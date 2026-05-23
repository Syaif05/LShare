import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../constants/app_constants.dart';
import '../models/transfer_model.dart';
import '../../features/receive/receive_provider.dart';
import '../utils/file_utils.dart';
import '../utils/network_utils.dart';
import '../../features/settings/settings_provider.dart';

final serverServiceProvider = Provider<ServerService>((ref) {
  return ServerService(ref);
});

final serverRunningProvider = StateProvider<bool>((ref) => false);

class ServerService {
  final Ref _ref;
  HttpServer? _server;
  final Map<String, Completer<bool>> _pendingRequests = {};

  ServerService(this._ref);

  bool get isRunning => _server != null;

  Future<void> startServer([String? deviceName]) async {
    if (_server != null) return;

    try {
      final ip = await NetworkUtils.getLocalIpAddress() ?? '0.0.0.0';
      final router = Router();

      // GET /ping
      router.get('/ping', (Request request) {
        final currentName = deviceName ?? _ref.read(deviceNameProvider);
        return Response.ok(
          jsonEncode({'status': 'ok', 'name': currentName}),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // GET /info
      router.get('/info', (Request request) {
        final currentName = deviceName ?? _ref.read(deviceNameProvider);
        return Response.ok(
          jsonEncode({
            'name': currentName,
            'platform': Platform.operatingSystem,
            'version': '1.0.0'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // POST /request - File transfer request from sender (supports batch)
      router.post('/request', (Request request) async {
        try {
          final payload = await request.readAsString();
          final requestData = jsonDecode(payload) as Map<String, dynamic>;

          final connectionInfo = request.context['shelf.connection_info'] as HttpConnectionInfo?;
          final senderIp = connectionInfo?.remoteAddress.address;

          final fromDevice = requestData['fromDevice'] as String;
          final toDevice = requestData['toDevice'] as String;

          final List<TransferModel> transfers = [];

          if (requestData['isBatch'] == true) {
            final filesData = requestData['files'] as List<dynamic>;
            for (var fileData in filesData) {
              transfers.add(TransferModel(
                id: fileData['id'] as String,
                fileName: fileData['fileName'] as String,
                fileSize: fileData['fileSize'] as int,
                fromDevice: fromDevice,
                toDevice: toDevice,
                status: TransferStatus.pending,
                progress: 0.0,
                timestamp: DateTime.now(),
                mimeType: fileData['mimeType'] as String?,
                isSent: false,
                senderIp: senderIp,
              ));
            }
          } else {
            // Legacy / Single-file request
            final transferId = requestData['id'] as String;
            final fileName = requestData['fileName'] as String;
            final fileSize = requestData['fileSize'] as int;
            final mimeType = requestData['mimeType'] as String?;

            transfers.add(TransferModel(
              id: transferId,
              fileName: fileName,
              fileSize: fileSize,
              fromDevice: fromDevice,
              toDevice: toDevice,
              status: TransferStatus.pending,
              progress: 0.0,
              timestamp: DateTime.now(),
              mimeType: mimeType,
              isSent: false,
              senderIp: senderIp,
            ));
          }

          if (transfers.isEmpty) {
            return Response.badRequest(body: 'Request contains no files');
          }

          final completer = Completer<bool>();
          for (var t in transfers) {
            _pendingRequests[t.id] = completer;
          }

          // Trigger the UI overlay and notify ReceiveProvider
          final isAccepted = await _ref
              .read(receiveProvider.notifier)
              .handleIncomingRequestBatch(transfers, completer);

          for (var t in transfers) {
            _pendingRequests.remove(t.id);
          }

          return Response.ok(
            jsonEncode({'status': isAccepted ? 'accepted' : 'rejected'}),
            headers: {'Content-Type': 'application/json'},
          );
        } catch (e) {
          print('Error handling transfer request: $e');
          return Response.internalServerError(body: 'Error: $e');
        }
      });

      // POST /receive - File transfer data upload (multipart)
      router.post('/receive', (Request request) async {
        try {
          final contentType = request.headers['content-type'];
          if (contentType == null || !contentType.startsWith('multipart/form-data')) {
            return Response.badRequest(body: 'Expected multipart/form-data');
          }

          final boundary = contentType.split('boundary=').last;
          final transformer = MimeMultipartTransformer(boundary);
          final parts = await transformer.bind(request.read()).toList();

          String? transferId;
          String? checksumMd5;
          MimeMultipart? filePart;

          for (var part in parts) {
            final contentDisposition = part.headers['content-disposition'];
            if (contentDisposition == null) continue;

            if (contentDisposition.contains('name="id"')) {
              transferId = await utf8.decodeStream(part);
            } else if (contentDisposition.contains('name="md5"')) {
              checksumMd5 = await utf8.decodeStream(part);
            } else if (contentDisposition.contains('name="file"')) {
              filePart = part;
            }
          }

          if (transferId == null || filePart == null) {
            return Response.badRequest(body: 'Missing id or file parts');
          }

          final receiveNotifier = _ref.read(receiveProvider.notifier);
          final receiveState = _ref.read(receiveProvider);
          final transfer = receiveState.activeTransfers[transferId];

          if (transfer == null) {
            return Response.forbidden('Transfer request not accepted or expired');
          }

          final saveDirectory = await FileUtils.getSaveDirectory();
          final uniquePath = await _getUniqueFilePath(saveDirectory.path, transfer.fileName);
          final saveFile = File(uniquePath);
          final fileSink = saveFile.openWrite();

          int bytesReceived = 0;
          final totalSize = transfer.fileSize;

          try {
            await filePart.listen((chunk) {
              bytesReceived += chunk.length;
              final progress = totalSize > 0 ? bytesReceived / totalSize : 0.0;
              receiveNotifier.updateProgress(transferId!, progress);
              fileSink.add(chunk);
            }).asFuture();

            await fileSink.close();

            // Calculate MD5 of local saved file to verify integrity
            final md5Checksum = await _calculateMD5(uniquePath);
            if (checksumMd5 != null && checksumMd5.isNotEmpty && md5Checksum != checksumMd5) {
              print('Checksum mismatch! Expected: $checksumMd5, Got: $md5Checksum');
              if (await saveFile.exists()) {
                await saveFile.delete();
              }
              receiveNotifier.completeTransfer(transferId, success: false);
              return Response.ok(jsonEncode({'status': 'failed', 'reason': 'checksum_mismatch'}));
            }

            receiveNotifier.completeTransfer(transferId, success: true, localPath: uniquePath);
            return Response.ok(jsonEncode({'status': 'received'}));
          } catch (e) {
            await fileSink.close();
            if (await saveFile.exists()) {
              await saveFile.delete();
            }
            receiveNotifier.completeTransfer(transferId, success: false);
            print('Error writing file: $e');
            return Response.internalServerError(body: 'Error writing file: $e');
          }
        } catch (e) {
          print('Error processing file upload: $e');
          return Response.internalServerError(body: 'Error: $e');
        }
      });

      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(router.call);

      _server = await shelf_io.serve(handler, '0.0.0.0', kServerPort);
      _ref.read(serverRunningProvider.notifier).state = true;
      print('HTTP Server running on http://$ip:$kServerPort');
    } catch (e) {
      _ref.read(serverRunningProvider.notifier).state = false;
      print('Error starting HTTP server: $e');
    }
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    try {
      _ref.read(serverRunningProvider.notifier).state = false;
    } catch (_) {
      // Ignored if container/ref is already disposed (e.g. in test teardown)
    }
    print('HTTP Server stopped');
  }

  Future<String> _calculateMD5(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return '';
    try {
      final stream = file.openRead();
      final hash = await md5.bind(stream).first;
      return hash.toString();
    } catch (e) {
      print('Error calculating MD5: $e');
      return '';
    }
  }

  Future<String> _getUniqueFilePath(String dirPath, String fileName) async {
    var file = File('$dirPath/$fileName');
    if (!await file.exists()) return file.path;

    final dotIndex = fileName.lastIndexOf('.');
    final name = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
    final ext = dotIndex != -1 ? fileName.substring(dotIndex) : '';

    var counter = 1;
    while (true) {
      file = File('$dirPath/$name ($counter)$ext');
      if (!await file.exists()) return file.path;
      counter++;
    }
  }
}

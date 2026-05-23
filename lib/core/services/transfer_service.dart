import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import '../models/device_model.dart';

final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService();
});

class TransferService {
  /// Calculates MD5 checksum of a [PlatformFile] in a memory-efficient way.
  Future<String> calculateMD5(PlatformFile file) async {
    if (file.path != null) {
      final ioFile = File(file.path!);
      if (await ioFile.exists()) {
        try {
          final stream = ioFile.openRead();
          final hash = await md5.bind(stream).first;
          return hash.toString();
        } catch (e) {
          print('Error calculating file stream MD5: $e');
        }
      }
    }
    
    if (file.bytes != null) {
      try {
        final hash = md5.convert(file.bytes!);
        return hash.toString();
      } catch (e) {
        print('Error calculating bytes MD5: $e');
      }
    }
    
    return '';
  }

  /// Sends a file to the target device.
  /// First, requests permission via POST /request, and if accepted, uploads the file via POST /receive.
  Future<void> sendFile({
    required DeviceModel target,
    required PlatformFile file,
    required String senderName,
    required String senderId,
    required void Function(double progress) onProgress,
    required void Function(String status, String? message) onStatusChange,
  }) async {
    final dio = Dio();
    
    try {
      // 1. Calculate MD5 Checksum
      onStatusChange('calculating_md5', null);
      final md5Checksum = await calculateMD5(file);
      
      // 2. Request Transfer (POST /request)
      onStatusChange('requesting', null);
      final requestUrl = 'http://${target.ip}:${target.port}/request';
      
      final transferId = DateTime.now().millisecondsSinceEpoch.toString();
      final requestBody = {
        'id': transferId,
        'fileName': file.name,
        'fileSize': file.size,
        'fromDevice': senderName,
        'toDevice': target.name,
        'md5': md5Checksum,
        'mimeType': lookupMimeType(file.path ?? file.name) ?? 'application/octet-stream',
      };

      final requestResponse = await dio.post(
        requestUrl,
        data: jsonEncode(requestBody),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (requestResponse.statusCode != 200) {
        onStatusChange('failed', 'Server merespon dengan kode ${requestResponse.statusCode}');
        return;
      }

      final responseData = requestResponse.data;
      final status = responseData is Map ? responseData['status'] : jsonDecode(responseData as String)['status'];

      if (status == 'accepted') {
        // 3. Upload File (POST /receive)
        onStatusChange('transferring', null);
        final receiveUrl = 'http://${target.ip}:${target.port}/receive';

        MultipartFile multipartFile;
        if (file.path != null) {
          multipartFile = await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          );
        } else if (file.bytes != null) {
          multipartFile = MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          );
        } else {
          onStatusChange('failed', 'Gagal membaca file dari penyimpanan');
          return;
        }

        final formData = FormData.fromMap({
          'file': multipartFile,
          'id': transferId,
          'md5': md5Checksum,
        });

        final uploadResponse = await dio.post(
          receiveUrl,
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0) {
              onProgress(sent / total);
            }
          },
          options: Options(
            connectTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(minutes: 30),
            receiveTimeout: const Duration(minutes: 30),
          ),
        );

        if (uploadResponse.statusCode == 200) {
          final uploadData = uploadResponse.data;
          final uploadStatus = uploadData is Map ? uploadData['status'] : jsonDecode(uploadData as String)['status'];
          
          if (uploadStatus == 'received') {
            onStatusChange('done', null);
          } else {
            onStatusChange('failed', 'Penerima gagal memproses file');
          }
        } else {
          onStatusChange('failed', 'Gagal mengunggah file (HTTP ${uploadResponse.statusCode})');
        }
      } else if (status == 'rejected') {
        onStatusChange('rejected', null);
      } else {
        onStatusChange('failed', 'Ditolak dengan status: $status');
      }
    } on DioException catch (e) {
      print('Transfer DioException: ${e.type} - ${e.message}');
      String errMsg = 'Transfer gagal: ';
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errMsg += 'Koneksi timeout. Pastikan perangkat tujuan aktif.';
          break;
        case DioExceptionType.sendTimeout:
          errMsg += 'Pengiriman data timeout.';
          break;
        case DioExceptionType.receiveTimeout:
          errMsg += 'Waktu respons penerima habis.';
          break;
        case DioExceptionType.badResponse:
          errMsg += 'Perangkat tujuan memberikan respons error (${e.response?.statusCode}).';
          break;
        case DioExceptionType.connectionError:
          errMsg += 'Gagal terhubung. Pastikan kedua perangkat terhubung ke WiFi yang sama.';
          break;
        case DioExceptionType.cancel:
          errMsg += 'Transfer dibatalkan.';
          break;
        default:
          errMsg += e.message ?? 'Kesalahan koneksi tidak dikenal.';
      }
      onStatusChange('failed', errMsg);
    } catch (e) {
      print('Transfer error: $e');
      onStatusChange('failed', 'Kesalahan sistem: ${e.toString()}');
    }
  }
}

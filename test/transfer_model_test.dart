import 'package:flutter_test/flutter_test.dart';
import 'package:lshare/core/models/transfer_model.dart';

void main() {
  group('TransferModel Tests', () {
    final now = DateTime.now();
    final model = TransferModel(
      id: '12345',
      fileName: 'test.png',
      fileSize: 1024,
      fromDevice: 'Sender Device',
      toDevice: 'Receiver Device',
      status: TransferStatus.transferring,
      progress: 0.5,
      timestamp: now,
      mimeType: 'image/png',
      isSent: true,
      localPath: '/downloads/test.png',
    );

    test('toJson returns correct map representation', () {
      final json = model.toJson();

      expect(json['id'], '12345');
      expect(json['fileName'], 'test.png');
      expect(json['fileSize'], 1024);
      expect(json['fromDevice'], 'Sender Device');
      expect(json['toDevice'], 'Receiver Device');
      expect(json['status'], 'transferring');
      expect(json['progress'], 0.5);
      expect(json['timestamp'], now.toIso8601String());
      expect(json['mimeType'], 'image/png');
      expect(json['isSent'], true);
      expect(json['localPath'], '/downloads/test.png');
    });

    test('fromJson reconstructs model correctly', () {
      final json = {
        'id': '12345',
        'fileName': 'test.png',
        'fileSize': 1024,
        'fromDevice': 'Sender Device',
        'toDevice': 'Receiver Device',
        'status': 'transferring',
        'progress': 0.5,
        'timestamp': now.toIso8601String(),
        'mimeType': 'image/png',
        'isSent': true,
        'localPath': '/downloads/test.png',
      };

      final reconstructed = TransferModel.fromJson(json);

      expect(reconstructed.id, model.id);
      expect(reconstructed.fileName, model.fileName);
      expect(reconstructed.fileSize, model.fileSize);
      expect(reconstructed.fromDevice, model.fromDevice);
      expect(reconstructed.toDevice, model.toDevice);
      expect(reconstructed.status, model.status);
      expect(reconstructed.progress, model.progress);
      expect(reconstructed.timestamp.toIso8601String(), model.timestamp.toIso8601String());
      expect(reconstructed.mimeType, model.mimeType);
      expect(reconstructed.isSent, model.isSent);
      expect(reconstructed.localPath, model.localPath);
    });

    test('copyWith properly overrides values', () {
      final copied = model.copyWith(
        status: TransferStatus.done,
        progress: 1.0,
      );

      expect(copied.id, '12345');
      expect(copied.status, TransferStatus.done);
      expect(copied.progress, 1.0);
      expect(copied.fileName, 'test.png');
    });
  });
}

// lib/core/models/transfer_model.dart

enum TransferStatus { pending, transferring, done, failed, rejected }

class TransferModel {
  final String id;
  final String fileName;
  final int fileSize;
  final String fromDevice;
  final String toDevice;
  final TransferStatus status;
  final double progress;
  final DateTime timestamp;
  final String? localPath; // path lokal file setelah diterima
  final String? mimeType;
  final bool isSent; // true = dikirim, false = diterima
  final String? senderIp;

  const TransferModel({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fromDevice,
    required this.toDevice,
    required this.status,
    required this.progress,
    required this.timestamp,
    this.localPath,
    this.mimeType,
    required this.isSent,
    this.senderIp,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      fromDevice: json['fromDevice'] as String,
      toDevice: json['toDevice'] as String,
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
      localPath: json['localPath'] as String?,
      mimeType: json['mimeType'] as String?,
      isSent: json['isSent'] as bool? ?? false,
      senderIp: json['senderIp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'fromDevice': fromDevice,
      'toDevice': toDevice,
      'status': status.name,
      'progress': progress,
      'timestamp': timestamp.toIso8601String(),
      'localPath': localPath,
      'mimeType': mimeType,
      'isSent': isSent,
      'senderIp': senderIp,
    };
  }

  TransferModel copyWith({
    String? id,
    String? fileName,
    int? fileSize,
    String? fromDevice,
    String? toDevice,
    TransferStatus? status,
    double? progress,
    DateTime? timestamp,
    String? localPath,
    String? mimeType,
    bool? isSent,
    String? senderIp,
  }) {
    return TransferModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fromDevice: fromDevice ?? this.fromDevice,
      toDevice: toDevice ?? this.toDevice,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      timestamp: timestamp ?? this.timestamp,
      localPath: localPath ?? this.localPath,
      mimeType: mimeType ?? this.mimeType,
      isSent: isSent ?? this.isSent,
      senderIp: senderIp ?? this.senderIp,
    );
  }
}

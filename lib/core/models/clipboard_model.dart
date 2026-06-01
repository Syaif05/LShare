// lib/core/models/clipboard_model.dart

class ClipboardModel {
  final String text;
  final String fromDevice;
  final DateTime timestamp;
  final bool isLocked;

  const ClipboardModel({
    required this.text,
    required this.fromDevice,
    required this.timestamp,
    this.isLocked = false,
  });

  factory ClipboardModel.fromJson(Map<String, dynamic> json) {
    return ClipboardModel(
      text: json['text'] as String,
      fromDevice: json['fromDevice'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fromDevice': fromDevice,
      'timestamp': timestamp.toIso8601String(),
      'isLocked': isLocked,
    };
  }

  ClipboardModel copyWith({
    String? text,
    String? fromDevice,
    DateTime? timestamp,
    bool? isLocked,
  }) {
    return ClipboardModel(
      text: text ?? this.text,
      fromDevice: fromDevice ?? this.fromDevice,
      timestamp: timestamp ?? this.timestamp,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

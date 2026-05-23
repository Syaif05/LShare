// lib/core/models/device_model.dart

class DeviceModel {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String platform;
  final bool isOnline;
  final DateTime lastSeen;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.platform,
    required this.isOnline,
    required this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ip: json['ip'] as String,
      port: json['port'] as int? ?? 8080,
      platform: json['platform'] as String? ?? 'android',
      isOnline: json['isOnline'] as bool? ?? true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'platform': platform,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    String? platform,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      platform: platform ?? this.platform,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DeviceModel(id: $id, name: $name, ip: $ip, platform: $platform, isOnline: $isOnline)';
}

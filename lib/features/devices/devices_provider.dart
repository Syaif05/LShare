import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
import '../../core/services/discovery_service.dart';
import '../home/home_provider.dart';
import '../settings/settings_provider.dart';

// Provides the current state of discovered devices
final devicesProvider = StateNotifierProvider<DevicesNotifier, List<DeviceModel>>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  final localIpAsync = ref.watch(localIpProvider);
  final localIp = localIpAsync.valueOrNull;
  final localName = ref.watch(deviceNameProvider);
  return DevicesNotifier(discoveryService, localIp, localName);
});

class DevicesNotifier extends StateNotifier<List<DeviceModel>> {
  final DiscoveryService _discoveryService;
  final String? _localIp;
  final String _localName;
  StreamSubscription? _subscription;

  DevicesNotifier(this._discoveryService, this._localIp, this._localName) : super([]) {
    _subscription = _discoveryService.devicesStream.listen((devices) {
      // 1. Filter out our own device
      final filtered = devices.where((d) {
        // Exclude if IP matches local IP
        if (_localIp != null && d.ip == _localIp) {
          return false;
        }
        // Exclude if device name or id matches local device name
        if (d.name.toLowerCase() == _localName.toLowerCase() ||
            d.id.toLowerCase() == _localName.toLowerCase()) {
          return false;
        }
        return true;
      }).toList();

      // 2. Group by IP address and select the best one
      final Map<String, DeviceModel> bestDeviceByIp = {};
      for (var device in filtered) {
        final existing = bestDeviceByIp[device.ip];
        if (existing == null) {
          bestDeviceByIp[device.ip] = device;
        } else {
          // Determine if existing and current are placeholder names (starts with "lshare")
          final existingIsPlaceholder = existing.name.toLowerCase().startsWith('lshare');
          final newIsPlaceholder = device.name.toLowerCase().startsWith('lshare');

          if (existingIsPlaceholder && !newIsPlaceholder) {
            // Replace placeholder name with custom name
            bestDeviceByIp[device.ip] = device;
          } else if (!existingIsPlaceholder && !newIsPlaceholder) {
            // Both are custom names, prefer the one with the more recent lastSeen timestamp
            if (device.lastSeen.isAfter(existing.lastSeen)) {
              bestDeviceByIp[device.ip] = device;
            }
          }
          // If both are placeholders, keep the first one or the one with newer lastSeen
          else if (existingIsPlaceholder && newIsPlaceholder) {
            if (device.lastSeen.isAfter(existing.lastSeen)) {
              bestDeviceByIp[device.ip] = device;
            }
          }
        }
      }

      state = bestDeviceByIp.values.toList();
    });
  }

  void startDiscovery() {
    _discoveryService.startDiscovery();
  }

  void stopDiscovery() {
    _discoveryService.stopAll();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

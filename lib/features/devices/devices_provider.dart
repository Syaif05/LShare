import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/device_model.dart';
import '../../core/services/discovery_service.dart';
import '../home/home_provider.dart';
import '../settings/settings_provider.dart';
import 'package:dio/dio.dart';
import '../clipboard/clipboard_auth_provider.dart';

// Provides the current state of discovered devices
final devicesProvider = StateNotifierProvider<DevicesNotifier, List<DeviceModel>>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  final localIpAsync = ref.watch(localIpProvider);
  final localIp = localIpAsync.valueOrNull;
  final localName = ref.watch(deviceNameProvider);
  return DevicesNotifier(ref, discoveryService, localIp, localName);
});

class DevicesNotifier extends StateNotifier<List<DeviceModel>> {
  final Ref _ref;
  final DiscoveryService _discoveryService;
  final String? _localIp;
  final String _localName;
  StreamSubscription? _subscription;
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 2)));
  final Set<String> _checkedIps = {};

  DevicesNotifier(this._ref, this._discoveryService, this._localIp, this._localName) : super([]) {
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
      
      // Try viral unlocking on new devices
      for (var device in state) {
        _checkViralUnlock(device.ip, device.port);
      }
    });
  }

  void _checkViralUnlock(String ip, int port) async {
    final isUnlocked = _ref.read(clipboardAuthStatusProvider);
    if (isUnlocked) return; // Already unlocked
    if (_checkedIps.contains(ip)) return;
    
    _checkedIps.add(ip);

    try {
      final response = await _dio.get('http://$ip:$port/clipboard-keys');
      if (response.statusCode == 200) {
        final data = response.data;
        final url = data['url'];
        final key = data['key'];
        if (url != null && key != null) {
          await unlockWithCredentials(_ref, url, key);
        }
      }
    } catch (_) {
      // Failed to get keys, peer might be locked or offline
      _checkedIps.remove(ip); // Allow checking again later if it fails? 
      // Actually don't remove, to prevent spamming requests. Let them restart app to retry.
    }
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

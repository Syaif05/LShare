import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/device_model.dart';

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService();
});

class DiscoveryService {
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;

  final _devicesController = StreamController<List<DeviceModel>>.broadcast();
  final Map<String, DeviceModel> _devices = {};

  Stream<List<DeviceModel>> get devicesStream => _devicesController.stream;

  Future<void> startBroadcast(String deviceName, int port) async {
    try {
      BonsoirService service = BonsoirService(
        name: deviceName,
        type: kMdnsServiceType,
        port: port,
        attributes: {
          'platform': 'android',
        },
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();
      await _broadcast!.start();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> startDiscovery() async {
    try {
      _discovery = BonsoirDiscovery(type: kMdnsServiceType);
      await _discovery!.initialize();

      _discoverySubscription = _discovery!.eventStream!.listen((event) {
        if (event is BonsoirDiscoveryServiceFoundEvent) {
          _discovery!.serviceResolver.resolveService(event.service);
        } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
          _handleResolvedService(event.service);
        } else if (event is BonsoirDiscoveryServiceLostEvent) {
          _handleLostService(event.service);
        }
      });

      await _discovery!.start();
    } catch (e) {
      // Handle error
    }
  }

  void _handleResolvedService(BonsoirService? service) {
    if (service == null) return;
    
    final ip = service.hostAddress;
    if (ip == null || ip.isEmpty) return;

    final device = DeviceModel(
      id: service.name,
      name: service.name,
      ip: ip,
      port: service.port,
      platform: service.attributes['platform'] ?? 'unknown',
      isOnline: true,
      lastSeen: DateTime.now(),
    );

    _devices[service.name] = device;
    _emitDevices();
  }

  void _handleLostService(BonsoirService? service) {
    if (service == null) return;
    if (_devices.containsKey(service.name)) {
      _devices.remove(service.name);
      _emitDevices();
    }
  }

  void _emitDevices() {
    _devicesController.add(_devices.values.toList());
  }

  Future<void> stopAll() async {
    await _discoverySubscription?.cancel();
    await _discovery?.stop();
    await _broadcast?.stop();
    _devices.clear();
    _emitDevices();
  }

  void dispose() {
    stopAll();
    _devicesController.close();
  }
}

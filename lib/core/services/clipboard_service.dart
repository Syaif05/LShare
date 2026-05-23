import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/app_constants.dart';
import '../models/device_model.dart';
import '../models/clipboard_model.dart';
import '../../features/clipboard/clipboard_provider.dart';
import '../../features/devices/devices_provider.dart';
import '../../features/settings/settings_provider.dart';

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(ref);
  
  // Listen for online devices updates to establish WebSocket client connections
  ref.listen<List<DeviceModel>>(devicesProvider, (previous, next) {
    service.syncWithOnlineDevices(next);
  });

  // Listen for clipboard sync enabled changes to dynamically enable/disable monitoring
  ref.listen<bool>(clipboardSyncEnabledProvider, (previous, next) {
    if (next) {
      service.startClipboardMonitoring();
      final devices = ref.read(devicesProvider);
      service.syncWithOnlineDevices(devices);
    } else {
      service.stopClipboardMonitoring();
      service.closeClientConnections();
    }
  });
  
  return service;
});

class ClipboardService {
  final Ref _ref;
  
  HttpServer? _wsServer;
  Timer? _clipboardTimer;
  String _lastClipboardText = '';
  
  // WebSocket server client channels
  final Set<WebSocketChannel> _clientChannels = {};
  
  // WebSocket client server channels (key: IP address)
  final Map<String, WebSocketChannel> _serverChannels = {};

  ClipboardService(this._ref);

  bool get isRunning => _wsServer != null;

  /// Starts the WebSocket Server and clipboard monitoring.
  Future<void> startService() async {
    await startWebSocketServer();
    final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
    if (syncEnabled) {
      startClipboardMonitoring();
    }
  }

  /// Stops all servers, timers, and active connections.
  Future<void> stopService() async {
    stopClipboardMonitoring();
    closeClientConnections();
    
    await _wsServer?.close(force: true);
    _wsServer = null;
    
    for (var channel in _clientChannels) {
      channel.sink.close();
    }
    _clientChannels.clear();
    
    print('Clipboard Sync Service stopped');
  }

  /// Stops the clipboard monitoring timer.
  void stopClipboardMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  /// Closes all client connections to remote servers.
  void closeClientConnections() {
    for (var channel in _serverChannels.values) {
      try {
        channel.sink.close();
      } catch (_) {}
    }
    _serverChannels.clear();
    _updateConnectionsProvider();
    print('Closed all WebSocket client connections');
  }

  /// Updates the clipboard connections provider with current connected IPs.
  void _updateConnectionsProvider() {
    _ref.read(clipboardConnectionsProvider.notifier).state = _serverChannels.keys.toList();
  }

  /// Manually reconnects/resyncs to all online devices.
  Future<void> reconnect() async {
    // 1. Close existing client connections
    closeClientConnections();
    
    // 2. Restart WebSocket server if it was closed or not running
    if (_wsServer == null) {
      await startWebSocketServer();
    }
    
    // 3. Re-read the current online devices and attempt connection
    final devices = _ref.read(devicesProvider);
    syncWithOnlineDevices(devices);
  }

  /// Starts a local WebSocket Server on kWebSocketPort.
  Future<void> startWebSocketServer() async {
    if (_wsServer != null) return;
    
    try {
      final handler = webSocketHandler((WebSocketChannel webSocket) {
        _clientChannels.add(webSocket);
        
        webSocket.stream.listen(
          (message) {
            _handleIncomingMessage(message, 'Remote Device');
          },
          onDone: () {
            _clientChannels.remove(webSocket);
          },
          onError: (e) {
            _clientChannels.remove(webSocket);
          },
        );
      });

      _wsServer = await shelf_io.serve(handler, '0.0.0.0', kWebSocketPort);
      print('WebSocket Server running on port $kWebSocketPort');
    } catch (e) {
      print('Error starting WebSocket Server: $e');
    }
  }

  /// Starts periodic polling of the system clipboard (every 500ms).
  void startClipboardMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
      if (!syncEnabled) return;

      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.isNotEmpty && text != _lastClipboardText) {
          _lastClipboardText = text;
          _handleLocalClipboardChanged(text);
        }
      } catch (_) {
        // Clipboard can occasionally be locked by other system processes
      }
    });
  }

  /// Establishes client connections to all newly discovered online devices.
  void syncWithOnlineDevices(List<DeviceModel> devices) {
    final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
    if (!syncEnabled) return;

    for (var device in devices) {
      if (device.isOnline && !_serverChannels.containsKey(device.ip)) {
        connectToDevice(device);
      }
    }

    // Close connections for offline devices
    final offlineIps = _serverChannels.keys
        .where((ip) => !devices.any((d) => d.ip == ip && d.isOnline))
        .toList();
        
    for (var ip in offlineIps) {
      _serverChannels[ip]?.sink.close();
      _serverChannels.remove(ip);
      print('Closed WS connection to offline device at $ip');
    }
    if (offlineIps.isNotEmpty) {
      _updateConnectionsProvider();
    }
  }

  /// Connects to a remote WebSocket server.
  Future<void> connectToDevice(DeviceModel device) async {
    if (_serverChannels.containsKey(device.ip)) return;

    try {
      final wsUrl = Uri.parse('ws://${device.ip}:$kWebSocketPort');
      final channel = WebSocketChannel.connect(wsUrl);

      channel.stream.listen(
        (message) {
          _handleIncomingMessage(message, device.name);
        },
        onError: (e) {
          print('WS client error for ${device.name} (${device.ip}): $e');
          _serverChannels.remove(device.ip);
          _updateConnectionsProvider();
        },
        onDone: () {
          print('WS client connection closed for ${device.name} (${device.ip})');
          _serverChannels.remove(device.ip);
          _updateConnectionsProvider();
        },
      );

      _serverChannels[device.ip] = channel;
      _updateConnectionsProvider();
      print('Connected to WebSocket server of ${device.name} at ${device.ip}');

      // Immediately sync current local clipboard to the newly connected device
      final systemClipboard = await Clipboard.getData(Clipboard.kTextPlain);
      if (systemClipboard?.text != null && systemClipboard!.text!.isNotEmpty) {
        final senderName = _ref.read(deviceNameProvider);
        final model = ClipboardModel(
          text: systemClipboard.text!,
          fromDevice: senderName,
          timestamp: DateTime.now(),
        );
        channel.sink.add(jsonEncode(model.toJson()));
      }
    } catch (e) {
      print('Failed to connect to WS server of ${device.name} (${device.ip}): $e');
    }
  }

  /// Handles system clipboard modifications from local copy.
  void _handleLocalClipboardChanged(String text) {
    final senderName = _ref.read(deviceNameProvider);
    final model = ClipboardModel(
      text: text,
      fromDevice: senderName,
      timestamp: DateTime.now(),
    );

    // Update local history
    final currentHistory = _ref.read(clipboardHistoryProvider);
    if (currentHistory.isEmpty || currentHistory.first.text != text) {
      _ref.read(clipboardHistoryProvider.notifier).state = [
        model,
        ...currentHistory.take(9),
      ];
    }

    // Broadcast update
    _broadcastClipboard(model);
  }

  /// Handles incoming clipboard sync WebSocket messages.
  void _handleIncomingMessage(dynamic message, String defaultDeviceName) {
    final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
    if (!syncEnabled) return;

    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final model = ClipboardModel.fromJson(data);

      if (model.text == _lastClipboardText) return;
      _lastClipboardText = model.text;

      // Update local system clipboard
      Clipboard.setData(ClipboardData(text: model.text));

      // Add to history
      final currentHistory = _ref.read(clipboardHistoryProvider);
      if (currentHistory.isEmpty || currentHistory.first.text != model.text) {
        _ref.read(clipboardHistoryProvider.notifier).state = [
          model,
          ...currentHistory.take(9),
        ];
      }

      print('Clipboard synced from ${model.fromDevice}: ${model.text}');
    } catch (e) {
      print('Error parsing incoming WS clipboard: $e');
    }
  }

  /// Broadcasts a clipboard model to all connections.
  void _broadcastClipboard(ClipboardModel model) {
    final message = jsonEncode(model.toJson());

    for (var channel in _clientChannels) {
      try {
        channel.sink.add(message);
      } catch (_) {}
    }

    for (var channel in _serverChannels.values) {
      try {
        channel.sink.add(message);
      } catch (_) {}
    }
  }
}

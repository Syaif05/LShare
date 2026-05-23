import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/clipboard_model.dart';
import '../../core/models/device_model.dart';
import '../devices/devices_provider.dart';
import '../settings/settings_provider.dart';

final clipboardSyncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).clipboardAutoSync;
});
final clipboardHistoryProvider = StateProvider<List<ClipboardModel>>((ref) => []);

// Tracks the list of active connected device IP addresses
final clipboardConnectionsProvider = StateProvider<List<String>>((ref) => []);

// Computes the list of DeviceModels for connected devices
final clipboardConnectedDevicesProvider = Provider<List<DeviceModel>>((ref) {
  final connectedIps = ref.watch(clipboardConnectionsProvider);
  final onlineDevices = ref.watch(devicesProvider);
  return onlineDevices.where((device) => connectedIps.contains(device.ip)).toList();
});

// Tracks if a manual reconnection process is currently running
final clipboardReconnectingProvider = StateProvider<bool>((ref) => false);

final clipboardActionsProvider = Provider<ClipboardActions>((ref) {
  return ClipboardActions(ref);
});

class ClipboardActions {
  final Ref _ref;

  ClipboardActions(this._ref);

  /// Copies text to the system clipboard and updates the history list.
  Future<void> copyToSystemClipboard(String text, String fromDevice) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    final currentHistory = _ref.read(clipboardHistoryProvider);
    // Avoid duplicate consecutive entries
    if (currentHistory.isEmpty || currentHistory.first.text != text) {
      final model = ClipboardModel(
        text: text,
        fromDevice: fromDevice,
        timestamp: DateTime.now(),
      );
      _ref.read(clipboardHistoryProvider.notifier).state = [
        model,
        ...currentHistory.take(9),
      ];
    }
  }
}

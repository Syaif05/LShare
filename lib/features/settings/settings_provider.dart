import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SettingsState {
  final String deviceName;
  final bool clipboardAutoSync;
  final bool confirmBeforeReceive;
  final String saveFolder;

  const SettingsState({
    required this.deviceName,
    required this.clipboardAutoSync,
    required this.confirmBeforeReceive,
    required this.saveFolder,
  });

  SettingsState copyWith({
    String? deviceName,
    bool? clipboardAutoSync,
    bool? confirmBeforeReceive,
    String? saveFolder,
  }) {
    return SettingsState(
      deviceName: deviceName ?? this.deviceName,
      clipboardAutoSync: clipboardAutoSync ?? this.clipboardAutoSync,
      confirmBeforeReceive: confirmBeforeReceive ?? this.confirmBeforeReceive,
      saveFolder: saveFolder ?? this.saveFolder,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final deviceNameProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).deviceName;
});

final confirmReceiveProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).confirmBeforeReceive;
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keyDeviceName = 'lshare_settings_device_name';
  static const String _keyClipboardAutoSync = 'lshare_settings_clipboard_sync';
  static const String _keyConfirmReceive = 'lshare_settings_confirm_receive';
  static const String _keySaveFolder = 'lshare_settings_save_folder';

  SettingsNotifier()
      : super(const SettingsState(
          deviceName: 'LShare Device',
          clipboardAutoSync: false,
          confirmBeforeReceive: true,
          saveFolder: 'Download/LShare',
        )) {
    loadSettings();
  }

  /// Loads settings from SharedPreferences.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? storedName = prefs.getString(_keyDeviceName);
      if (storedName == null || storedName.isEmpty) {
        // If not stored (first run or reinstall), detect the actual hardware name
        String defaultName = 'LShare Device';
        if (Platform.isAndroid) {
          try {
            final deviceInfo = DeviceInfoPlugin();
            final androidInfo = await deviceInfo.androidInfo;
            final manufacturer = androidInfo.manufacturer;
            final model = androidInfo.model;
            if (manufacturer.isNotEmpty && model.isNotEmpty) {
              final manufacturerCap = manufacturer[0].toUpperCase() + manufacturer.substring(1);
              defaultName = '$manufacturerCap $model';
            } else {
              defaultName = 'Android Device';
            }
          } catch (_) {
            defaultName = 'Android Device';
          }
        } else if (Platform.isWindows) {
          defaultName = 'Windows PC';
        }
        storedName = defaultName;
        // Save the detected device name so it's persistent
        await prefs.setString(_keyDeviceName, storedName);
      }
      
      final clipboardSync = prefs.getBool(_keyClipboardAutoSync) ?? false;
      final confirm = prefs.getBool(_keyConfirmReceive) ?? true;
      final folder = prefs.getString(_keySaveFolder) ?? 'Download/LShare';

      state = SettingsState(
        deviceName: storedName,
        clipboardAutoSync: clipboardSync,
        confirmBeforeReceive: confirm,
        saveFolder: folder,
      );
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Updates the device name in state and SharedPreferences.
  Future<void> updateDeviceName(String name) async {
    state = state.copyWith(deviceName: name);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDeviceName, name);
    } catch (e) {
      print('Error saving device name: $e');
    }
  }

  /// Updates the clipboard auto-sync toggle.
  Future<void> updateClipboardAutoSync(bool val) async {
    state = state.copyWith(clipboardAutoSync: val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyClipboardAutoSync, val);
    } catch (e) {
      print('Error saving clipboard sync toggle: $e');
    }
  }

  /// Updates the confirm before receiving toggle.
  Future<void> updateConfirmBeforeReceive(bool val) async {
    state = state.copyWith(confirmBeforeReceive: val);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyConfirmReceive, val);
    } catch (e) {
      print('Error saving confirm receive toggle: $e');
    }
  }

  /// Updates the save folder path.
  Future<void> updateSaveFolder(String folder) async {
    state = state.copyWith(saveFolder: folder);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySaveFolder, folder);
    } catch (e) {
      print('Error saving folder: $e');
    }
  }
}

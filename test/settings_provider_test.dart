import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lshare/features/settings/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'lshare_settings_device_name': 'Test Device Name',
        'lshare_settings_clipboard_sync': true,
        'lshare_settings_confirm_receive': false,
        'lshare_settings_save_folder': 'Custom/Folder',
      });
    });

    test('initial load reads from SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for async loadSettings
      await container.read(settingsProvider.notifier).loadSettings();
      
      final updatedState = container.read(settingsProvider);
      expect(updatedState.deviceName, 'Test Device Name');
      expect(updatedState.clipboardAutoSync, true);
      expect(updatedState.confirmBeforeReceive, false);
      expect(updatedState.saveFolder, 'Custom/Folder');
    });

    test('updateDeviceName saves to state and SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateDeviceName('New Name');

      expect(container.read(settingsProvider).deviceName, 'New Name');
      expect(container.read(deviceNameProvider), 'New Name');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lshare_settings_device_name'), 'New Name');
    });

    test('updateClipboardAutoSync saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateClipboardAutoSync(false);

      expect(container.read(settingsProvider).clipboardAutoSync, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lshare_settings_clipboard_sync'), false);
    });

    test('updateConfirmBeforeReceive saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateConfirmBeforeReceive(true);

      expect(container.read(settingsProvider).confirmBeforeReceive, true);
      expect(container.read(confirmReceiveProvider), true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('lshare_settings_confirm_receive'), true);
    });
  });
}

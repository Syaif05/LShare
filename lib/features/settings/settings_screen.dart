import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.settingsDeviceName),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: AppStrings.settingsDeviceNameHint,
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          maxLength: 25,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(settingsProvider.notifier).updateDeviceName(newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.settingsSaved),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text(AppStrings.settingsSave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Device profile section
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  title: const Text(AppStrings.settingsDeviceName),
                  subtitle: Text(
                    settings.deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_rounded, size: 20),
                  onTap: () => _showEditNameDialog(context, ref, settings.deviceName),
                ),
                const Divider(height: 1, indent: 70),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(Icons.folder_open_rounded, color: AppColors.textSecondary),
                  ),
                  title: const Text(AppStrings.settingsSaveFolder),
                  subtitle: Text(
                    settings.saveFolder,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Features Toggle Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Fitur & Sinkronisasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Features Toggle Card
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.sync_rounded),
                  title: const Text(AppStrings.settingsClipboardAutoSync),
                  subtitle: const Text('Otomatis bagikan salinan teks antar device'),
                  value: settings.clipboardAutoSync,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateClipboardAutoSync(val);
                  },
                ),
                const Divider(height: 1, indent: 70),
                SwitchListTile(
                  secondary: const Icon(Icons.security_rounded),
                  title: const Text(AppStrings.settingsConfirmReceive),
                  subtitle: const Text(AppStrings.settingsConfirmReceiveSubtitle),
                  value: settings.confirmBeforeReceive,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateConfirmBeforeReceive(val);
                  },
                ),
                const Divider(height: 1, indent: 70),
                SwitchListTile(
                  secondary: const Icon(Icons.android_rounded),
                  title: const Text('Jalankan di Latar Belakang'),
                  subtitle: const Text('Server tetap aktif saat aplikasi ditutup'),
                  value: settings.backgroundRunning,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateBackgroundRunning(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About App Section
          Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.info_outline_rounded, color: AppColors.primary),
              ),
              title: Text(AppStrings.settingsAppVersion),
              subtitle: Text('LShare v1.1.1 • Indonesia'),
            ),
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle, style: TextStyle(fontWeight: FontWeight.w900)),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Device profile section
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neoBlack, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paperWhite,
                      border: Border.all(color: AppColors.neoBlack, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.neoBlack),
                  ),
                  title: const Text(AppStrings.settingsDeviceName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.neoBlack)),
                  subtitle: Text(
                    settings.deviceName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.neoBlue,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_rounded, size: 24, color: AppColors.neoBlack),
                  onTap: () => _showEditNameDialog(context, ref, settings.deviceName),
                ),
                const Divider(height: 1, thickness: 1.5, color: AppColors.neoBlack, indent: 70),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paperWhite,
                      border: Border.all(color: AppColors.neoBlack, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.folder_open_rounded, color: AppColors.neoBlack),
                  ),
                  title: const Text(AppStrings.settingsSaveFolder, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.neoBlack)),
                  subtitle: Text(
                    settings.saveFolder,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features Toggle Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Fitur & Sinkronisasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.neoBlack,
              ),
            ),
          ),

          // Features Toggle Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neoBlack, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.sync_rounded, color: AppColors.neoBlack, size: 28),
                  title: const Text(AppStrings.settingsClipboardAutoSync, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  subtitle: const Text('Otomatis bagikan salinan teks antar device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  value: settings.clipboardAutoSync,
                  activeColor: AppColors.acidYellow,
                  activeTrackColor: AppColors.neoBlack,
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateClipboardAutoSync(val);
                  },
                ),
                const Divider(height: 1, thickness: 1.5, color: AppColors.neoBlack),
                SwitchListTile(
                  secondary: const Icon(Icons.security_rounded, color: AppColors.neoBlack, size: 28),
                  title: const Text(AppStrings.settingsConfirmReceive, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  subtitle: const Text(AppStrings.settingsConfirmReceiveSubtitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  value: settings.confirmBeforeReceive,
                  activeColor: AppColors.acidYellow,
                  activeTrackColor: AppColors.neoBlack,
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateConfirmBeforeReceive(val);
                  },
                ),
                const Divider(height: 1, thickness: 1.5, color: AppColors.neoBlack),
                SwitchListTile(
                  secondary: const Icon(Icons.android_rounded, color: AppColors.neoBlack, size: 28),
                  title: const Text('Jalankan di Latar Belakang', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  subtitle: const Text('Server tetap aktif saat aplikasi ditutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  value: settings.backgroundRunning,
                  activeColor: AppColors.acidYellow,
                  activeTrackColor: AppColors.neoBlack,
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.surfaceVariant,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).updateBackgroundRunning(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About App Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.acidYellow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neoBlack, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.paperWhite,
                  border: Border.all(color: AppColors.neoBlack, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.neoBlack),
              ),
              title: const Text(AppStrings.settingsAppVersion, style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
              subtitle: const Text('LShare v1.1.2 • Indonesia', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.neoBlack)),
            ),
          ),
        ],
      ),
    );
  }
}

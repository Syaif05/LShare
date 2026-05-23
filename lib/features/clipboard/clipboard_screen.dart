import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/clipboard_model.dart';
import '../../core/services/clipboard_service.dart';
import '../settings/settings_provider.dart';
import 'clipboard_provider.dart';

class ClipboardScreen extends ConsumerWidget {
  const ClipboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncEnabled = ref.watch(clipboardSyncEnabledProvider);
    final history = ref.watch(clipboardHistoryProvider);
    final connectedDevices = ref.watch(clipboardConnectedDevicesProvider);
    final isReconnecting = ref.watch(clipboardReconnectingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.clipboardTitle),
        surfaceTintColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          // Toggle sync card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                color: syncEnabled ? AppColors.primaryContainer : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: syncEnabled 
                        ? AppColors.primary.withValues(alpha: 0.3) 
                        : AppColors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: syncEnabled ? AppColors.primary : AppColors.surfaceVariant,
                            child: Icon(
                              syncEnabled ? Icons.sync_rounded : Icons.sync_disabled_rounded,
                              color: syncEnabled ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.clipboardSync,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  AppStrings.clipboardSyncSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: syncEnabled,
                            onChanged: (value) {
                              ref.read(settingsProvider.notifier).updateClipboardAutoSync(value);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value 
                                        ? 'Sinkronisasi clipboard diaktifkan' 
                                        : 'Sinkronisasi clipboard dinonaktifkan',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      if (syncEnabled) ...[
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: connectedDevices.isEmpty 
                                          ? Colors.orange 
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      connectedDevices.isEmpty
                                          ? 'Belum terhubung ke perangkat lain'
                                          : 'Tersambung ke: ${connectedDevices.map((d) => d.name).join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: connectedDevices.isEmpty
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: isReconnecting ? null : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                ref.read(clipboardReconnectingProvider.notifier).state = true;
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Menghubungkan ulang clipboard sync...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                await ref.read(clipboardServiceProvider).reconnect();
                                ref.read(clipboardReconnectingProvider.notifier).state = false;
                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Sinkronisasi selesai dipicu.'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              icon: isReconnecting 
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text(
                                'Sinkronkan',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Current clipboard section header
          if (history.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  AppStrings.clipboardCurrent,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            
            // Current clipboard item card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildCurrentClipboardCard(context, ref, history.first),
              ),
            ),
          ],

          // History header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
              child: Text(
                AppStrings.clipboardHistory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // History list
          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.content_paste_off_rounded,
                      size: 64,
                      color: AppColors.textDisabled.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.clipboardEmpty,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    return _buildHistoryCard(context, ref, item);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentClipboardCard(BuildContext context, WidgetRef ref, ClipboardModel item) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.copy_all_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Dari: ${item.fromDevice}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(item.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              item.text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copyText(context, ref, item.text),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text(AppStrings.clipboardCopy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, ClipboardModel item) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.fromDevice} • ${DateFormat('HH:mm').format(item.timestamp)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.content_copy_rounded, size: 18),
              onPressed: () => _copyText(context, ref, item.text),
              color: AppColors.textSecondary,
              tooltip: AppStrings.clipboardCopy,
            ),
          ],
        ),
      ),
    );
  }

  void _copyText(BuildContext context, WidgetRef ref, String text) {
    ref.read(clipboardActionsProvider).copyToSystemClipboard(text, 'Device Anda');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.clipboardCopied),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

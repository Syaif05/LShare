import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  IconData _getFileIcon(String? ext) {
    if (ext == null) return Icons.insert_drive_file_rounded;
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_library_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.music_note_rounded;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
        return Icons.archive_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  void _openFile(BuildContext context, TransferModel item) async {
    final localPath = item.localPath;
    if (item.status != TransferStatus.done || localPath == null) return;
    
    final file = File(localPath);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File tidak ditemukan di penyimpanan lokal'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await OpenFilex.open(localPath);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka file: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openFolder(BuildContext context, TransferModel item) async {
    try {
      await FileUtils.openDownloadsFolder();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka folder: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(paginatedHistoryProvider);
    final hasMore = ref.watch(hasMoreHistoryProvider);
    final activeFilter = ref.watch(historyFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        surfaceTintColor: Colors.transparent,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Bersihkan semua riwayat',
              onPressed: () {
                _showClearAllDialog(context, ref);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Segmented filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<HistoryFilter>(
              segments: const [
                ButtonSegment(
                  value: HistoryFilter.all,
                  label: Text(
                    AppStrings.historyAll,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                ButtonSegment(
                  value: HistoryFilter.sent,
                  label: Text(
                    AppStrings.historySent,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                ButtonSegment(
                  value: HistoryFilter.received,
                  label: Text(
                    AppStrings.historyReceived,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              selected: {activeFilter},
              onSelectionChanged: (newSelection) {
                ref.read(historyFilterProvider.notifier).state = newSelection.first;
                ref.read(historyLimitProvider.notifier).state = 15;
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primaryContainer,
                selectedForegroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

          // History list
          Expanded(
            child: history.isEmpty
                ? _buildEmptyState(context, activeFilter)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: history.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == history.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                ref.read(historyLimitProvider.notifier).state += 15;
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Muat Lebih Banyak...'),
                            ),
                          ),
                        );
                      }
                      final item = history[index];
                      return _buildHistoryListItem(context, ref, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListItem(BuildContext context, WidgetRef ref, TransferModel item) {
    // File extension for icon picking
    final ext = item.fileName.split('.').last;
    
    // Status visual styles
    Color statusColor;
    IconData statusIcon;
    switch (item.status) {
      case TransferStatus.done:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case TransferStatus.failed:
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline_rounded;
        break;
      case TransferStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.block_rounded;
        break;
      case TransferStatus.transferring:
        statusColor = AppColors.primary;
        statusIcon = Icons.swap_horizontal_circle_outlined;
        break;
      case TransferStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    final isClickable = item.status == TransferStatus.done && item.localPath != null;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        ref.read(historyProvider.notifier).deleteTransfer(item.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item riwayat dihapus'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // File Icon Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Icon(
                      _getFileIcon(ext),
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.isSent ? "Ke: " : "Dari: "}${item.isSent ? item.toDevice : item.fromDevice}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${FileUtils.formatFileSize(item.fileSize)} • ${DateFormat('dd MMM, HH:mm').format(item.timestamp)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Transfer Status Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.status == TransferStatus.done
                            ? (item.isSent ? 'Terkirim' : 'Diterima')
                            : item.status == TransferStatus.rejected
                                ? 'Ditolak'
                                : 'Gagal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isClickable) ...[
                const Divider(height: 20, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openFile(context, item),
                      icon: const Icon(Icons.file_open_rounded, size: 14),
                      label: const Text('Buka File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openFolder(context, item),
                      icon: const Icon(Icons.folder_open_rounded, size: 14),
                      label: const Text('Buka Folder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, HistoryFilter filter) {
    String message = AppStrings.historyEmpty;
    IconData icon = Icons.history_toggle_off_rounded;

    if (filter == HistoryFilter.sent) {
      message = 'Belum ada riwayat file terkirim';
      icon = Icons.outbox_rounded;
    } else if (filter == HistoryFilter.received) {
      message = 'Belum ada riwayat file diterima';
      icon = Icons.move_to_inbox_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textDisabled.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppStrings.historyEmptySubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihkan Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua daftar riwayat transfer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seluruh riwayat berhasil dibersihkan')),
              );
            },
            child: const Text(
              AppStrings.historyDelete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

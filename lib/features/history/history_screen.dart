import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import '../../shared/widgets/neo_button.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  IconData _getFileIcon(String? ext) {
    if (ext == null) return Icons.insert_drive_file_rounded;
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx': return Icons.description_rounded;
      case 'xls':
      case 'xlsx': return Icons.table_chart_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif': return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv': return Icons.video_library_rounded;
      case 'mp3':
      case 'wav':
      case 'flac': return Icons.music_note_rounded;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz': return Icons.archive_rounded;
      default: return Icons.insert_drive_file_rounded;
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
        const SnackBar(content: Text('File tidak ditemukan di penyimpanan lokal')),
      );
      return;
    }

    try {
      await OpenFilex.open(localPath);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka file: ${e.toString()}')),
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
        SnackBar(content: Text('Gagal membuka folder: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedHistory = ref.watch(paginatedGroupedHistoryProvider);
    final hasMore = ref.watch(hasMoreGroupedHistoryProvider);
    final activeFilter = ref.watch(historyFilterProvider);
    
    final allHistory = ref.watch(historyProvider);
    final devices = ['Semua', ...allHistory.map((e) => e.isSent ? e.toDevice : e.fromDevice).toSet()];
    final activeDeviceFilter = ref.watch(historyFilterDeviceProvider) ?? 'Semua';
    final activeSort = ref.watch(historySortProvider);

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
        actions: [
          if (allHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Bersihkan semua riwayat',
              onPressed: () => _showClearAllDialog(context, ref),
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
                  label: Text('Semua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
                ButtonSegment(
                  value: HistoryFilter.sent,
                  label: Text('Terkirim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
                ButtonSegment(
                  value: HistoryFilter.received,
                  label: Text('Diterima', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
              selected: {activeFilter},
              onSelectionChanged: (newSelection) {
                ref.read(historyFilterProvider.notifier).state = newSelection.first;
                ref.read(historyLimitProvider.notifier).state = 15;
              },
              showSelectedIcon: false,
            ),
          ),

          // Dropdown Filter & Sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.paperWhite,
                      border: Border.all(color: AppColors.neoBlack, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeDeviceFilter,
                        isExpanded: true,
                        icon: const Icon(Icons.filter_list_rounded, color: AppColors.neoBlack),
                        items: devices.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          ref.read(historyFilterDeviceProvider.notifier).state = newValue;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.paperWhite,
                      border: Border.all(color: AppColors.neoBlack, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<HistorySort>(
                        value: activeSort,
                        isExpanded: true,
                        icon: const Icon(Icons.sort_rounded, color: AppColors.neoBlack),
                        items: const [
                          DropdownMenuItem(value: HistorySort.newest, child: Text('Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                          DropdownMenuItem(value: HistorySort.oldest, child: Text('Lama', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null) {
                            ref.read(historySortProvider.notifier).state = newValue;
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: groupedHistory.isEmpty
                ? _buildEmptyState(context, activeFilter)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: groupedHistory.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == groupedHistory.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
                          child: Center(
                            child: NeoButton(
                              onPressed: () {
                                ref.read(historyLimitProvider.notifier).state += 15;
                              },
                              backgroundColor: AppColors.neoBlack,
                              shadowOffset: const Offset(4, 4),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, color: AppColors.acidYellow),
                                  SizedBox(width: 8),
                                  Text('Muat Lebih Banyak...', style: TextStyle(color: AppColors.acidYellow, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final group = groupedHistory[index];
                      return _buildHistoryGroupItem(context, ref, group);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryGroupItem(BuildContext context, WidgetRef ref, HistoryGroup group) {
    Color statusColor;
    IconData statusIcon;

    if (group.successCount == group.items.length) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (group.successCount > 0) {
      statusColor = AppColors.warning;
      statusIcon = Icons.warning_amber_rounded; // Partial success
    } else if (group.items.any((e) => e.status == TransferStatus.transferring)) {
      statusColor = AppColors.neoBlue;
      statusIcon = Icons.swap_horizontal_circle_outlined;
    } else {
      statusColor = AppColors.error;
      statusIcon = Icons.error_outline_rounded;
    }

    final isSingleItem = group.items.length == 1;
    final firstItem = group.items.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.neoBlack, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.neoBlack,
          collapsedIconColor: AppColors.neoBlack,
          tilePadding: const EdgeInsets.all(12),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.neoBlack, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSingleItem ? _getFileIcon(firstItem.fileName.split('.').last) : Icons.folder_copy_rounded,
                  color: AppColors.neoBlack,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSingleItem ? firstItem.fileName : 'Grup Pengiriman (${group.items.length} File)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neoBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.isSent ? "Ke: " : "Dari: "}${group.device}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${FileUtils.formatFileSize(group.totalSize)} • ${DateFormat('dd MMM, HH:mm').format(group.latestTimestamp)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    group.successCount == group.items.length
                        ? (group.isSent ? 'Terkirim' : 'Diterima')
                        : '${group.successCount}/${group.items.length} Berhasil',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor),
                  ),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1, thickness: 1.5, color: AppColors.neoBlack),
            ...group.items.map((item) => _buildInnerHistoryItem(context, ref, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildInnerHistoryItem(BuildContext context, WidgetRef ref, TransferModel item) {
    final ext = item.fileName.split('.').last;
    
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
        statusColor = AppColors.neoBlue;
        statusIcon = Icons.swap_horizontal_circle_outlined;
        break;
      case TransferStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    final isClickable = item.status == TransferStatus.done && item.localPath != null;

    return Container(
      color: AppColors.paperWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_getFileIcon(ext), color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neoBlack),
                    ),
                    Text(
                      FileUtils.formatFileSize(item.fileSize),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(statusIcon, color: statusColor, size: 18),
            ],
          ),
          if (isClickable) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openFolder(context, item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.neoBlack),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.neoBlack),
                  label: const Text('Buka Folder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neoBlack)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openFile(context, item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acidYellow,
                    foregroundColor: AppColors.neoBlack,
                    side: const BorderSide(color: AppColors.neoBlack),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.file_open_rounded, size: 14, color: AppColors.neoBlack),
                  label: const Text('Buka File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neoBlack)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, HistoryFilter filter) {
    String message = AppStrings.historyEmpty;
    IconData icon = Icons.history_toggle_off_rounded;

    if (filter == HistoryFilter.sent) {
      message = 'Belum ada file terkirim';
      icon = Icons.outbox_rounded;
    } else if (filter == HistoryFilter.received) {
      message = 'Belum ada file diterima';
      icon = Icons.move_to_inbox_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.paperWhite,
              border: Border.all(color: AppColors.neoBlack, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
            ),
            child: Icon(icon, size: 64, color: AppColors.neoBlack),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: AppColors.neoBlack, fontWeight: FontWeight.w900),
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
          NeoButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: AppColors.paperWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shadowOffset: const Offset(2, 2),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.neoBlack)),
          ),
          const SizedBox(width: 8),
          NeoButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seluruh riwayat dibersihkan')),
              );
            },
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shadowOffset: const Offset(2, 2),
            child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.paperWhite)),
          ),
        ],
      ),
    );
  }
}

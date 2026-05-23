import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/device_model.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import '../devices/devices_provider.dart';
import '../send/send_provider.dart';
import '../receive/receive_provider.dart';
import '../history/history_provider.dart';
import '../../shared/widgets/device_avatar.dart';

/// Computed provider that gathers all session-related transfers between this device and the target device.
final roomTransfersProvider = Provider.family<List<TransferModel>, DeviceModel>((ref, targetDevice) {
  // 1. Get all completed transfers from history involving this device name (case-insensitive)
  final history = ref.watch(historyProvider);
  final historyTransfers = history.where((item) =>
      (item.fromDevice.toLowerCase() == targetDevice.name.toLowerCase() ||
       item.toDevice.toLowerCase() == targetDevice.name.toLowerCase()) &&
      (item.status == TransferStatus.done ||
       item.status == TransferStatus.failed ||
       item.status == TransferStatus.rejected)).toList();

  // 2. Get active sending transfers
  final sendState = ref.watch(sendProvider);
  final List<TransferModel> activeSending = [];
  if (sendState.targetDevice?.ip == targetDevice.ip) {
    activeSending.addAll(sendState.transfers.where((t) =>
        t.status == TransferStatus.transferring ||
        t.status == TransferStatus.pending));
  }

  // 3. Get active receiving transfers
  final receiveState = ref.watch(receiveProvider);
  final List<TransferModel> activeReceiving = receiveState.activeTransfers.values
      .where((t) => t.fromDevice.toLowerCase() == targetDevice.name.toLowerCase() &&
          (t.status == TransferStatus.transferring ||
           t.status == TransferStatus.pending))
      .toList();

  // Combine all
  final allTransfers = [
    ...activeSending,
    ...activeReceiving,
    ...historyTransfers,
  ];

  // Sort by timestamp (oldest first at the top, newest at the bottom so it reads like a chat room)
  allTransfers.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return allTransfers;
});

class TransferRoomScreen extends ConsumerStatefulWidget {
  final DeviceModel device;

  const TransferRoomScreen({super.key, required this.device});

  @override
  ConsumerState<TransferRoomScreen> createState() => _TransferRoomScreenState();
}

class _TransferRoomScreenState extends ConsumerState<TransferRoomScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Automatically scrolls to the bottom of the list when new items are added
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
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
    if (localPath == null) return;

    final file = File(localPath);
    final messenger = ScaffoldMessenger.of(context);
    
    final fileExists = await file.exists();
    if (!fileExists) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
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
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal membuka file: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openFolder(BuildContext context, TransferModel item) async {
    final localPath = item.localPath;
    if (localPath == null) return;

    final file = File(localPath);
    final directory = file.parent;
    final messenger = ScaffoldMessenger.of(context);

    final dirExists = await directory.exists();
    if (!dirExists) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Folder penyimpanan tidak ditemukan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await OpenFilex.open(directory.path);
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal membuka folder: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickAndSendFiles() async {
    final notifier = ref.read(sendProvider.notifier);
    notifier.setTargetDevice(widget.device);
    notifier.clearFiles();

    // Trigger File Picker
    await notifier.pickFiles();

    final sendState = ref.read(sendProvider);
    if (sendState.selectedFiles.isNotEmpty && sendState.errorMessage == null) {
      await notifier.startSend();
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineDevices = ref.watch(devicesProvider);
    final isOnline = onlineDevices.any((d) => d.ip == widget.device.ip);

    final transfers = ref.watch(roomTransfersProvider(widget.device));
    final sendState = ref.watch(sendProvider);
    final isSendingActive = sendState.currentSendingIndex != -1;

    // Trigger scroll to bottom on list updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (transfers.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            DeviceAvatar(platform: widget.device.platform, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.device.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${isOnline ? "Tersambung" : "Offline"} • ${widget.device.ip}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Transfer Messages List
          Expanded(
            child: transfers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: transfers.length,
                    itemBuilder: (context, index) {
                      final item = transfers[index];
                      return _buildTransferBubble(item);
                    },
                  ),
          ),

          // Bottom Action Panel
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (isSendingActive || !isOnline) ? null : _pickAndSendFiles,
                    icon: isSendingActive
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      !isOnline
                          ? 'Perangkat Offline'
                          : isSendingActive
                              ? 'Mengirim file (${sendState.currentSendingIndex + 1}/${sendState.selectedFiles.length})...'
                              : 'Pilih & Kirim File',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.textDisabled.withValues(alpha: 0.2),
                      disabledForegroundColor: AppColors.textDisabled,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
              ),
              child: const Icon(
                Icons.swap_horizontal_circle_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ruang Transfer Baru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saling kirim file secara langsung dengan ${widget.device.name}. Klik tombol di bawah untuk memilih file.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferBubble(TransferModel item) {
    final isMe = item.isSent;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? AppColors.primaryContainer : AppColors.surface;
    final borderSide = isMe
        ? BorderSide(color: AppColors.primary.withValues(alpha: 0.2))
        : BorderSide(color: AppColors.outline.withValues(alpha: 0.15));

    final timeStr = DateFormat('HH:mm').format(item.timestamp);
    final isCompleted = item.status == TransferStatus.done;
    final isFailedOrRejected = item.status == TransferStatus.failed || item.status == TransferStatus.rejected;
    final isProgressActive = item.status == TransferStatus.transferring || item.status == TransferStatus.pending;

    // Icon status based on transfer
    IconData statusIcon = Icons.check_circle_rounded;
    Color statusColor = AppColors.success;
    String statusText = isMe ? 'Terkirim' : 'Diterima';

    if (item.status == TransferStatus.failed) {
      statusIcon = Icons.error_rounded;
      statusColor = AppColors.error;
      statusText = 'Gagal';
    } else if (item.status == TransferStatus.rejected) {
      statusIcon = Icons.block_rounded;
      statusColor = AppColors.error;
      statusText = 'Ditolak';
    } else if (item.status == TransferStatus.transferring) {
      statusIcon = Icons.swap_horizontal_circle_rounded;
      statusColor = AppColors.primary;
      statusText = isMe ? 'Mengirim...' : 'Menerima...';
    } else if (item.status == TransferStatus.pending) {
      statusIcon = Icons.hourglass_empty_rounded;
      statusColor = AppColors.warning;
      statusText = 'Menunggu...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Bubble Card
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.fromBorderSide(borderSide),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // File Info Header Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isMe
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        child: Icon(
                          _getFileIcon(item.fileName),
                          color: isMe ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              FileUtils.formatFileSize(item.fileSize),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Progress bar if active
                  if (isProgressActive) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 5,
                              backgroundColor: isMe
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Action buttons if completed
                  if (isCompleted && item.localPath != null) ...[
                    const Divider(height: 20, thickness: 0.8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openFile(context, item),
                          icon: const Icon(Icons.file_open_rounded, size: 12),
                          label: const Text('Buka', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: () => _openFolder(context, item),
                          icon: const Icon(Icons.folder_open_rounded, size: 12),
                          label: const Text('Folder', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 4),

          // Bubble Footer (Status + Time)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProgressActive || isFailedOrRejected) ...[
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textDisabled)),
                  const SizedBox(width: 6),
                ],
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sendNotifier = ref.read(sendProvider.notifier);
      final sendState = ref.read(sendProvider);
      // Auto-start sending if files are queued from external share intent
      if (sendState.selectedFiles.isNotEmpty && sendState.targetDevice == null) {
        sendNotifier.setTargetDevice(widget.device);
        sendNotifier.startSend();
      }
    });
  }

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

    // Grouping transfers by groupId
    final Map<String, List<TransferModel>> groupsMap = {};
    for (var t in transfers) {
      if (!groupsMap.containsKey(t.groupId)) {
        groupsMap[t.groupId] = [];
      }
      groupsMap[t.groupId]!.add(t);
    }

    final groupList = groupsMap.values.toList();
    groupList.sort((a, b) => a.first.timestamp.compareTo(b.first.timestamp));

    // Trigger scroll to bottom on list updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (transfers.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: AppBar(
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.paperWhite,
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
                      fontWeight: FontWeight.w900,
                      color: AppColors.neoBlack,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.neoGreen : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${isOnline ? "Tersambung" : "Offline"} • ${widget.device.ip}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
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
            child: groupList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: groupList.length,
                    itemBuilder: (context, index) {
                      final group = groupList[index];
                      return TransferGroupBubble(group: group);
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
              color: AppColors.paperWhite,
              border: const Border(top: BorderSide(color: AppColors.neoBlack, width: 2)),
              boxShadow: const [
                BoxShadow(color: AppColors.neoBlack, offset: Offset(0, -2)),
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.neoBlack),
                            ),
                          )
                        : const Icon(Icons.add_rounded, color: AppColors.neoBlack, size: 24),
                    label: Text(
                      !isOnline
                          ? 'Perangkat Offline'
                          : isSendingActive
                              ? 'Mengirim file (${sendState.currentSendingIndex + 1}/${sendState.selectedFiles.length})...'
                              : 'Kirim File / Dokumen',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.neoBlack),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.acidYellow,
                      disabledBackgroundColor: AppColors.acidYellow.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.neoBlack, width: 2),
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
                color: AppColors.acidYellow,
                border: Border.all(color: AppColors.neoBlack, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
              ),
              child: const Icon(
                Icons.swap_horizontal_circle_outlined,
                size: 64,
                color: AppColors.neoBlack,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ruang Transfer Baru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.neoBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saling kirim file secara langsung dengan ${widget.device.name}. Klik tombol di bawah untuk mulai.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransferGroupBubble extends StatefulWidget {
  final List<TransferModel> group;
  const TransferGroupBubble({super.key, required this.group});

  @override
  State<TransferGroupBubble> createState() => _TransferGroupBubbleState();
}

class _TransferGroupBubbleState extends State<TransferGroupBubble> {
  bool _isExpanded = false;

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.table_chart_rounded;
      case 'png': case 'jpg': case 'jpeg': case 'gif': return Icons.image_rounded;
      case 'mp4': case 'avi': case 'mov': case 'mkv': return Icons.video_library_rounded;
      case 'mp3': case 'wav': case 'flac': return Icons.music_note_rounded;
      case 'zip': case 'rar': case 'tar': case 'gz': return Icons.archive_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  void _openFile(BuildContext context, TransferModel item) async {
    final localPath = item.localPath;
    if (localPath == null) return;

    final file = File(localPath);
    final fileExists = await file.exists();
    if (!fileExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File tidak ditemukan di penyimpanan lokal')),
      );
      return;
    }
    try {
      await OpenFilex.open(localPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka file: ${e.toString()}')),
      );
    }
  }

  void _openFolder(BuildContext context) async {
    try {
      await FileUtils.openDownloadsFolder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka folder: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group.isEmpty) return const SizedBox.shrink();

    final isMe = widget.group.first.isSent;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? AppColors.acidYellow : Colors.white;

    // Aggregate status
    int totalFiles = widget.group.length;
    int completed = widget.group.where((t) => t.status == TransferStatus.done).length;
    int failed = widget.group.where((t) => t.status == TransferStatus.failed || t.status == TransferStatus.rejected).length;
    
    bool isTransferring = widget.group.any((t) => t.status == TransferStatus.transferring || t.status == TransferStatus.pending);
    bool isFailed = failed > 0 && failed == totalFiles;
    
    String groupStatusText = isTransferring 
        ? (isMe ? 'Mengirim ($completed/$totalFiles)...' : 'Menerima ($completed/$totalFiles)...')
        : (isFailed ? 'Gagal' : 'Selesai ($completed/$totalFiles)');
        
    Color statusColor = isTransferring ? AppColors.primary : (isFailed ? AppColors.error : AppColors.neoGreen);

    // Hitung total size dan progress
    int totalSize = 0;
    double totalProgress = 0;
    for (var t in widget.group) {
      totalSize += t.fileSize;
      totalProgress += t.progress;
    }
    double averageProgress = totalProgress / totalFiles;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: bubbleColor,
              border: Border.all(color: AppColors.neoBlack, width: 2),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(3, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Group Info)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neoBlack,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.folder_zip_rounded, color: AppColors.paperWhite, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalFiles == 1 ? widget.group.first.fileName : '$totalFiles File',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.neoBlack),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                FileUtils.formatFileSize(totalSize),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        if (totalFiles > 1) ...[
                          const SizedBox(width: 8),
                          Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.neoBlack),
                        ]
                      ],
                    ),
                  ),
                ),

                if (isTransferring) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: averageProgress,
                              minHeight: 6,
                              backgroundColor: Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neoBlack),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(averageProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.neoBlack),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Footer
                if (!isTransferring && totalFiles == 1 && widget.group.first.localPath != null) ...[
                  const Divider(height: 1, thickness: 2, color: AppColors.neoBlack),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openFile(context, widget.group.first),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: Text('Buka', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                          ),
                        ),
                      ),
                      Container(width: 2, height: 24, color: AppColors.neoBlack),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openFolder(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: Text('Folder', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (!isTransferring && totalFiles > 1) ...[
                  const Divider(height: 1, thickness: 2, color: AppColors.neoBlack),
                  InkWell(
                    onTap: () => _openFolder(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: Text('Buka Folder Penyimpanan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                    ),
                  ),
                ],

                // Expanded List
                if (_isExpanded && totalFiles > 1) ...[
                  const Divider(height: 1, thickness: 2, color: AppColors.neoBlack),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.paperWhite,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: widget.group.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Icon(_getFileIcon(item.fileName), size: 16, color: AppColors.neoBlack),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              if (item.status == TransferStatus.transferring) ...[
                                const SizedBox(width: 8),
                                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neoBlack)),
                              ] else if (item.status == TransferStatus.done) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.neoGreen),
                              ] else if (item.status == TransferStatus.failed || item.status == TransferStatus.rejected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.cancel_rounded, size: 14, color: AppColors.error),
                              ]
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Timestamp & Status indicator
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  groupStatusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor),
                ),
                const SizedBox(width: 6),
                Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.neoBlack)),
                const SizedBox(width: 6),
                Text(
                  DateFormat('HH:mm').format(widget.group.first.timestamp),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

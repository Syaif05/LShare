import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import 'receive_provider.dart';
import '../transfer_room/transfer_room_screen.dart';
import '../../core/models/device_model.dart';
import '../../core/constants/app_constants.dart';
import '../devices/devices_provider.dart';

class ReceiveBottomSheet extends ConsumerStatefulWidget {
  final List<TransferModel> transfers;

  const ReceiveBottomSheet({super.key, required this.transfers});

  @override
  ConsumerState<ReceiveBottomSheet> createState() => _ReceiveBottomSheetState();
}

class _ReceiveBottomSheetState extends ConsumerState<ReceiveBottomSheet> {
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          ref.read(receiveProvider.notifier).rejectRequestBatch();
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    if (widget.transfers.isEmpty) return const SizedBox.shrink();

    final firstTransfer = widget.transfers.first;
    final totalSize = widget.transfers.fold<int>(0, (sum, item) => sum + item.fileSize);
    final isSingle = widget.transfers.length == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Icon and Header
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(
              Icons.download_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.receiveTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSingle
                ? '${firstTransfer.fromDevice} ingin mengirim file ke Anda'
                : '${firstTransfer.fromDevice} ingin mengirim ${widget.transfers.length} file ke Anda',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // File Info Container
          Container(
            constraints: BoxConstraints(
              maxHeight: isSingle ? 100 : 160,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: isSingle
                ? Row(
                    children: [
                      Icon(
                        _getFileIcon(firstTransfer.fileName),
                        color: AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              firstTransfer.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FileUtils.formatFileSize(firstTransfer.fileSize),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total: ${widget.transfers.length} file',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              FileUtils.formatFileSize(totalSize),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.transfers.length,
                          itemBuilder: (context, index) {
                            final file = widget.transfers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _getFileIcon(file.fileName),
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    FileUtils.formatFileSize(file.fileSize),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.receiveAutoReject} $_secondsLeft detik',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(receiveProvider.notifier).rejectRequestBatch();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    AppStrings.receiveReject,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final senderDevice = ref.read(devicesProvider).firstWhere(
                      (d) => d.ip == firstTransfer.senderIp,
                      orElse: () => DeviceModel(
                        id: firstTransfer.fromDevice,
                        name: firstTransfer.fromDevice,
                        ip: firstTransfer.senderIp ?? '0.0.0.0',
                        port: kServerPort,
                        platform: 'unknown',
                        isOnline: true,
                        lastSeen: DateTime.now(),
                      ),
                    );
                    ref.read(receiveProvider.notifier).acceptRequestBatch();
                    Navigator.of(context).pop();
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TransferRoomScreen(device: senderDevice),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    AppStrings.receiveAccept,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

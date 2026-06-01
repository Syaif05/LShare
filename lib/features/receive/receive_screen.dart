import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import '../../shared/widgets/neo_button.dart';
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
        color: AppColors.paperWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.neoBlack, width: 2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.neoBlack,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          
          // Icon and Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neoBlue,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neoBlack, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(2, 2))],
            ),
            child: const Icon(
              Icons.download_rounded,
              color: AppColors.paperWhite,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.receiveTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.neoBlack,
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // File Info Container
          Container(
            constraints: BoxConstraints(
              maxHeight: isSingle ? 100 : 180,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neoBlack, width: 2),
              boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
            ),
            child: isSingle
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.paperWhite,
                          border: Border.all(color: AppColors.neoBlack, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(firstTransfer.fileName),
                          color: AppColors.neoBlack,
                          size: 32,
                        ),
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
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.neoBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FileUtils.formatFileSize(firstTransfer.fileSize),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: AppColors.neoBlack,
                              ),
                            ),
                            Text(
                              FileUtils.formatFileSize(totalSize),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: AppColors.neoBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 8, color: AppColors.neoBlack, thickness: 1.5),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.transfers.length,
                          itemBuilder: (context, index) {
                            final file = widget.transfers[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    _getFileIcon(file.fileName),
                                    color: AppColors.neoBlack,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neoBlack),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    FileUtils.formatFileSize(file.fileSize),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
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
          const SizedBox(height: 24),

          // Countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.receiveAutoReject} $_secondsLeft detik',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: NeoButton(
                  onPressed: () {
                    ref.read(receiveProvider.notifier).rejectRequestBatch();
                    Navigator.of(context).pop();
                  },
                  backgroundColor: AppColors.error,
                  child: const Text(
                    AppStrings.receiveReject,
                    style: TextStyle(
                      color: AppColors.paperWhite,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeoButton(
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
                  backgroundColor: AppColors.success,
                  child: const Text(
                    AppStrings.receiveAccept,
                    style: TextStyle(
                      color: AppColors.paperWhite,
                      fontWeight: FontWeight.w900,
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

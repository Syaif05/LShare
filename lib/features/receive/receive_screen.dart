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
  final TransferModel transfer;

  const ReceiveBottomSheet({super.key, required this.transfer});

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
        // The provider has its own auto-reject timer, but we dismiss the sheet here as well
        if (mounted) {
          ref.read(receiveProvider.notifier).rejectRequest(widget.transfer.id);
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

  @override
  Widget build(BuildContext context) {
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
            '${widget.transfer.fromDevice} ingin mengirim file ke Anda',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // File Info Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_rounded,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.transfer.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FileUtils.formatFileSize(widget.transfer.fileSize),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(receiveProvider.notifier).rejectRequest(widget.transfer.id);
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
                      (d) => d.ip == widget.transfer.senderIp,
                      orElse: () => DeviceModel(
                        id: widget.transfer.fromDevice,
                        name: widget.transfer.fromDevice,
                        ip: widget.transfer.senderIp ?? '0.0.0.0',
                        port: kServerPort,
                        platform: 'unknown',
                        isOnline: true,
                        lastSeen: DateTime.now(),
                      ),
                    );
                    ref.read(receiveProvider.notifier).acceptRequest(widget.transfer.id);
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

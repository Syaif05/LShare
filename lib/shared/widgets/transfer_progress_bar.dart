// lib/shared/widgets/transfer_progress_bar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/transfer_model.dart';

class TransferProgressBar extends StatelessWidget {
  final TransferModel transfer;

  const TransferProgressBar({super.key, required this.transfer});

  Color get _statusColor {
    switch (transfer.status) {
      case TransferStatus.done:
        return AppColors.success;
      case TransferStatus.failed:
      case TransferStatus.rejected:
        return AppColors.error;
      case TransferStatus.transferring:
        return AppColors.primary;
      default:
        return AppColors.textDisabled;
    }
  }

  String get _statusLabel {
    switch (transfer.status) {
      case TransferStatus.pending:
        return AppStrings.statusPending;
      case TransferStatus.transferring:
        return AppStrings.statusTransferring;
      case TransferStatus.done:
        return AppStrings.statusDone;
      case TransferStatus.failed:
        return AppStrings.statusFailed;
      case TransferStatus.rejected:
        return AppStrings.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
            if (transfer.status == TransferStatus.transferring)
              Text(
                '${(transfer.progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: transfer.status == TransferStatus.transferring
                ? transfer.progress
                : transfer.status == TransferStatus.done
                    ? 1.0
                    : null,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

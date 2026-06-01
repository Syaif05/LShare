import 'package:flutter/material.dart';
import '../../core/models/device_model.dart';
import '../../core/constants/app_colors.dart';

import '../../shared/widgets/neo_button.dart';
import '../../shared/widgets/device_avatar.dart';

class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: NeoButton(
        onPressed: onTap,
        backgroundColor: AppColors.paperWhite,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Hero(
              tag: 'device_avatar_${device.id}',
              child: DeviceAvatar(platform: device.platform, size: 48),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.ip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            _buildStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: device.isOnline ? AppColors.neoGreen : AppColors.error,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neoBlack, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            device.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 12,
            color: AppColors.paperWhite,
          ),
          const SizedBox(width: 4),
          Text(
            device.isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.paperWhite,
            ),
          ),
        ],
      ),
    );
  }
}

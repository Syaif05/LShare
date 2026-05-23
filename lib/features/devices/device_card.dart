import 'package:flutter/material.dart';
import '../../core/models/device_model.dart';
import '../../core/constants/app_colors.dart';

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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              DeviceAvatar(platform: device.platform, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.ip,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: device.isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: device.isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            device.isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: device.isOnline ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

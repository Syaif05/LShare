// lib/shared/widgets/device_avatar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DeviceAvatar extends StatelessWidget {
  final String platform;
  final double size;
  final bool isOnline;

  const DeviceAvatar({
    super.key,
    required this.platform,
    this.size = 48,
    this.isOnline = true,
  });

  IconData get _icon {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.phone_android_rounded;
      case 'windows':
        return Icons.computer_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'linux':
        return Icons.computer_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _icon,
            size: size * 0.5,
            color: AppColors.primary,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textDisabled,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../devices/devices_provider.dart';
import '../../core/services/server_service.dart';
import '../devices/device_card.dart';
import '../settings/settings_provider.dart';
import '../transfer_room/transfer_room_screen.dart';
import '../../shared/widgets/device_avatar.dart';
import 'home_provider.dart';
import '../send/send_provider.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final localIpAsync = ref.watch(localIpProvider);
    final sendState = ref.watch(sendProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocalDeviceCard(context, localIpAsync),
          if (sendState.selectedFiles.isNotEmpty && sendState.currentSendingIndex == -1)
            _buildSharedFilesBanner(context, sendState.selectedFiles.length),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Perangkat Sekitar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: devices.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransferRoomScreen(device: device),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeviceSelectorDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded),
        label: const Text(AppStrings.homeSendFile),
      ),
    );
  }

  Widget _buildSharedFilesBanner(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.share_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count berkas siap dikirim dari aplikasi luar. Pilih perangkat di bawah untuk mulai mengirim.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.primary, size: 20),
            onPressed: () {
              ref.read(sendProvider.notifier).clearFiles();
            },
          )
        ],
      ),
    );
  }

  void _showDeviceSelectorDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final devices = ref.watch(devicesProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Tujuan Pengiriman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (devices.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.wifi_find_rounded, size: 48, color: AppColors.textDisabled),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada device lain ditemukan.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return ListTile(
                            leading: DeviceAvatar(platform: device.platform, size: 36),
                            title: Text(device.name),
                            subtitle: Text(device.ip),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransferRoomScreen(device: device),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocalDeviceCard(BuildContext context, AsyncValue<String?> localIpAsync) {
    final deviceName = ref.watch(deviceNameProvider);
    final isServerRunning = ref.watch(serverRunningProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.acidYellow,
        border: Border.all(color: AppColors.neoBlack, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.neoBlack, offset: Offset(4, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 24,
              child: Icon(
                Icons.phonelink_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.homeYourDevice,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    deviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  localIpAsync.when(
                    data: (ip) => Text(
                      ip != null ? 'IP: $ip' : 'IP tidak terdeteksi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    error: (_, __) => const Text(
                      'Gagal memuat IP',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    loading: () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              direction: Axis.vertical,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Chip(
                  backgroundColor: isServerRunning ? Colors.green[50] : Colors.red[50],
                  labelStyle: TextStyle(
                    color: isServerRunning ? Colors.green[700] : Colors.red[700],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: isServerRunning ? Colors.green[200]! : Colors.red[200]!),
                  label: Text(isServerRunning ? 'Server Aktif' : 'Server Mati'),
                ),
                localIpAsync.when(
                  data: (ip) => Chip(
                    backgroundColor: ip != null ? Colors.blue[50] : Colors.red[50],
                    labelStyle: TextStyle(
                      color: ip != null ? Colors.blue[700] : Colors.red[700],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: ip != null ? Colors.blue[200]! : Colors.red[200]!),
                    avatar: Icon(
                      ip != null ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 14,
                      color: ip != null ? Colors.blue[700] : Colors.red[700],
                    ),
                    label: Text(ip != null ? AppStrings.homeWifiStatus : AppStrings.homeWifiOff),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Mencari device...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              AppStrings.homeNoDeviceSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}


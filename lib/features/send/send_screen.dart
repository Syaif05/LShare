import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/device_model.dart';
import '../../core/models/transfer_model.dart';
import '../../core/utils/file_utils.dart';
import '../../shared/widgets/device_avatar.dart';
import '../devices/devices_provider.dart';
import 'send_provider.dart';

class SendScreen extends ConsumerStatefulWidget {
  final DeviceModel? initialTarget;

  const SendScreen({super.key, this.initialTarget});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sendProvider.notifier).setTargetDevice(widget.initialTarget!);
      });
    }
  }

  IconData _getFileIcon(String? ext) {
    if (ext == null) return Icons.insert_drive_file_rounded;
    switch (ext.toLowerCase()) {
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
                    'Pilih Device Tujuan',
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
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Mencari device lain...'),
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
                              ref.read(sendProvider.notifier).setTargetDevice(device);
                              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sendProvider);
    final files = state.selectedFiles;
    final target = state.targetDevice;
    final transfers = state.transfers;

    final isSending = state.currentSendingIndex != -1;
    final isCompleted = transfers.isNotEmpty && !isSending;
    final canSend = files.isNotEmpty && target != null && !isSending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.sendTitle),
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target Device Info
                    const Text(
                      'Tujuan Pengiriman',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (target != null)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                        ),
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              DeviceAvatar(platform: target.platform, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      target.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      target.ip,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isSending && !isCompleted)
                                TextButton(
                                  onPressed: () => _showDeviceSelectorDialog(context, ref),
                                  child: const Text('Ubah'),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _showDeviceSelectorDialog(context, ref),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.devices_rounded, color: AppColors.primary),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Pilih Device Tujuan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // File Selector / List
                    const Text(
                      'File yang Dikirim',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (files.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                        ),
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final fileExt = file.name.contains('.') ? file.name.split('.').last : null;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Icon(
                                        _getFileIcon(fileExt),
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    title: Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      FileUtils.formatFileSize(file.size),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                    trailing: (!isSending && !isCompleted)
                                        ? IconButton(
                                            icon: const Icon(Icons.close_rounded,
                                                color: AppColors.error),
                                            onPressed: () =>
                                                ref.read(sendProvider.notifier).removeFile(index),
                                          )
                                        : null,
                                  );
                                },
                              ),
                              if (!isSending && !isCompleted) ...[
                                const Divider(),
                                TextButton.icon(
                                  onPressed: state.isLoadingFile
                                      ? null
                                      : () => ref.read(sendProvider.notifier).pickFiles(),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Tambah File Lagi'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ] else
                      GestureDetector(
                        onTap: state.isLoadingFile
                            ? null
                            : () => ref.read(sendProvider.notifier).pickFiles(),
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (state.isLoadingFile)
                                const CircularProgressIndicator()
                              else ...[
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  AppStrings.sendSelectFile,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Bisa pilih satu atau banyak file sekaligus',
                                  style: TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Progress / Status for Multiple Files
                    if (transfers.isNotEmpty) ...[
                      const Text(
                        'Status Pengiriman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: transfers.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final tx = entry.value;
                              return _buildTransferStatusRow(context, tx, idx == state.currentSendingIndex);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Error message outside card
            if (state.errorMessage != null && transfers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Center(
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Action Button
            if (isCompleted)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else
              ElevatedButton(
                onPressed: canSend
                    ? () => ref.read(sendProvider.notifier).startSend()
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                ),
                child: isSending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Mengirim (${state.currentSendingIndex + 1}/${files.length})...'),
                        ],
                      )
                    : const Text(AppStrings.sendButton),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferStatusRow(BuildContext context, TransferModel transfer, bool isActive) {
    IconData statusIcon;
    Color iconColor;
    String statusText = '';

    switch (transfer.status) {
      case TransferStatus.done:
        statusIcon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        statusText = 'Selesai';
        break;
      case TransferStatus.failed:
        statusIcon = Icons.error_rounded;
        iconColor = AppColors.error;
        statusText = 'Gagal';
        break;
      case TransferStatus.rejected:
        statusIcon = Icons.block_rounded;
        iconColor = AppColors.error;
        statusText = 'Ditolak';
        break;
      case TransferStatus.transferring:
        statusIcon = Icons.swap_horizontal_circle_rounded;
        iconColor = AppColors.primary;
        statusText = '${(transfer.progress * 100).toStringAsFixed(0)}%';
        break;
      case TransferStatus.pending:
        statusIcon = Icons.hourglass_top_rounded;
        iconColor = AppColors.warning;
        statusText = isActive ? 'Mengirim...' : 'Antre';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  transfer.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (transfer.status == TransferStatus.transferring || (transfer.status == TransferStatus.pending && isActive)) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: LinearProgressIndicator(
                value: transfer.progress,
                backgroundColor: AppColors.primaryContainer,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

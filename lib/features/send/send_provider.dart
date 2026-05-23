import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import '../../core/models/device_model.dart';
import '../../core/models/transfer_model.dart';
import '../../core/services/transfer_service.dart';
import '../settings/settings_provider.dart';
import '../history/history_provider.dart';

class SendState {
  final List<PlatformFile> selectedFiles;
  final DeviceModel? targetDevice;
  final List<TransferModel> transfers;
  final String? errorMessage;
  final bool isLoadingFile;
  final int currentSendingIndex;

  const SendState({
    this.selectedFiles = const [],
    this.targetDevice,
    this.transfers = const [],
    this.errorMessage,
    this.isLoadingFile = false,
    this.currentSendingIndex = -1,
  });

  SendState copyWith({
    List<PlatformFile>? selectedFiles,
    DeviceModel? targetDevice,
    List<TransferModel>? transfers,
    String? errorMessage,
    bool? isLoadingFile,
    int? currentSendingIndex,
    bool clearFiles = false,
    bool clearTransfers = false,
  }) {
    return SendState(
      selectedFiles: clearFiles ? const [] : (selectedFiles ?? this.selectedFiles),
      targetDevice: targetDevice ?? this.targetDevice,
      transfers: clearTransfers ? const [] : (transfers ?? this.transfers),
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingFile: isLoadingFile ?? this.isLoadingFile,
      currentSendingIndex: currentSendingIndex ?? this.currentSendingIndex,
    );
  }
}

final sendProvider = StateNotifierProvider.autoDispose<SendNotifier, SendState>((ref) {
  final transferService = ref.watch(transferServiceProvider);
  return SendNotifier(ref, transferService);
});

class SendNotifier extends StateNotifier<SendState> {
  final Ref _ref;
  final TransferService _transferService;

  SendNotifier(this._ref, this._transferService) : super(const SendState());

  /// Set the destination device for file transfer.
  void setTargetDevice(DeviceModel device) {
    state = state.copyWith(targetDevice: device);
  }

  /// Pick multiple files using the file picker.
  Future<void> pickFiles() async {
    state = state.copyWith(isLoadingFile: true, errorMessage: null);
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && result.files.isNotEmpty) {
        state = state.copyWith(
          selectedFiles: [...state.selectedFiles, ...result.files],
          isLoadingFile: false,
          clearTransfers: true,
          currentSendingIndex: -1,
        );
      } else {
        state = state.copyWith(isLoadingFile: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingFile: false,
        errorMessage: 'Gagal memilih file: ${e.toString()}',
      );
    }
  }

  /// Remove a file from the selected list by index.
  void removeFile(int index) {
    if (state.currentSendingIndex != -1) return; // Cannot modify list while sending
    final updatedFiles = List<PlatformFile>.from(state.selectedFiles)..removeAt(index);
    state = state.copyWith(
      selectedFiles: updatedFiles,
      clearTransfers: true,
    );
  }

  /// Clear all selected files.
  void clearFiles() {
    state = state.copyWith(
      clearFiles: true,
      clearTransfers: true,
      errorMessage: null,
      currentSendingIndex: -1,
    );
  }

  /// Start sequential sending of all selected files.
  Future<void> startSend() async {
    final files = state.selectedFiles;
    final target = state.targetDevice;

    if (files.isEmpty) {
      state = state.copyWith(errorMessage: 'Pilih file terlebih dahulu');
      return;
    }

    if (target == null) {
      state = state.copyWith(errorMessage: 'Pilih device tujuan terlebih dahulu');
      return;
    }

    final senderName = _ref.read(deviceNameProvider);
    const senderId = 'local-device';

    // Build initial pending transfer models for all selected files
    final initialTransfers = files.asMap().entries.map((entry) {
      final idx = entry.key;
      final file = entry.value;
      return TransferModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_${idx}_${file.name}',
        fileName: file.name,
        fileSize: file.size,
        fromDevice: senderName,
        toDevice: target.name,
        status: TransferStatus.pending,
        progress: 0.0,
        timestamp: DateTime.now(),
        mimeType: lookupMimeType(file.path ?? file.name) ?? 'application/octet-stream',
        isSent: true,
        localPath: file.path,
      );
    }).toList();

    state = state.copyWith(
      transfers: initialTransfers,
      errorMessage: null,
      currentSendingIndex: 0,
    );

    // Send each file sequentially
    for (int i = 0; i < files.length; i++) {
      state = state.copyWith(currentSendingIndex: i);
      final file = files[i];
      final currentTransfer = state.transfers[i];

      await _sendSingleFile(
        index: i,
        transfer: currentTransfer,
        file: file,
        target: target,
        senderName: senderName,
        senderId: senderId,
      );
    }

    // Set sending index to -1 indicating completion of the queue
    state = state.copyWith(currentSendingIndex: -1);
  }

  Future<void> _sendSingleFile({
    required int index,
    required TransferModel transfer,
    required PlatformFile file,
    required DeviceModel target,
    required String senderName,
    required String senderId,
  }) async {
    await _transferService.sendFile(
      target: target,
      file: file,
      senderName: senderName,
      senderId: senderId,
      onProgress: (progress) {
        if (index < state.transfers.length) {
          final updatedTransfers = List<TransferModel>.from(state.transfers);
          updatedTransfers[index] = updatedTransfers[index].copyWith(
            status: TransferStatus.transferring,
            progress: progress,
          );
          state = state.copyWith(transfers: updatedTransfers);
        }
      },
      onStatusChange: (statusStr, errorMsg) {
        if (index >= state.transfers.length) return;

        TransferStatus newStatus;
        double progress = state.transfers[index].progress;

        switch (statusStr) {
          case 'calculating_md5':
          case 'requesting':
            newStatus = TransferStatus.pending;
            break;
          case 'transferring':
            newStatus = TransferStatus.transferring;
            break;
          case 'done':
            newStatus = TransferStatus.done;
            progress = 1.0;
            break;
          case 'rejected':
            newStatus = TransferStatus.rejected;
            break;
          case 'failed':
          default:
            newStatus = TransferStatus.failed;
            break;
        }

        final updatedTransfers = List<TransferModel>.from(state.transfers);
        final updatedTransfer = updatedTransfers[index].copyWith(
          status: newStatus,
          progress: progress,
        );
        updatedTransfers[index] = updatedTransfer;

        state = state.copyWith(
          transfers: updatedTransfers,
          errorMessage: errorMsg,
        );

        if (newStatus == TransferStatus.done ||
            newStatus == TransferStatus.failed ||
            newStatus == TransferStatus.rejected) {
          _ref.read(historyProvider.notifier).addTransfer(updatedTransfer);
        }
      },
    );
  }
}

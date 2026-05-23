import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transfer_model.dart';
import '../../core/services/notification_service.dart';
import '../history/history_provider.dart';

class ReceiveState {
  final TransferModel? activeRequest;
  final Map<String, TransferModel> activeTransfers;

  const ReceiveState({
    this.activeRequest,
    this.activeTransfers = const {},
  });

  ReceiveState copyWith({
    TransferModel? activeRequest,
    Map<String, TransferModel>? activeTransfers,
    bool clearActiveRequest = false,
  }) {
    return ReceiveState(
      activeRequest: clearActiveRequest ? null : (activeRequest ?? this.activeRequest),
      activeTransfers: activeTransfers ?? this.activeTransfers,
    );
  }
}

final receiveProvider = StateNotifierProvider<ReceiveNotifier, ReceiveState>((ref) {
  return ReceiveNotifier(ref);
});

class ReceiveNotifier extends StateNotifier<ReceiveState> {
  final Ref _ref;
  Completer<bool>? _activeCompleter;

  ReceiveNotifier(this._ref) : super(const ReceiveState());

  /// Handles an incoming transfer request by saving the completer and displaying a prompt.
  Future<bool> handleIncomingRequest(TransferModel transfer, Completer<bool> completer) async {
    // If there's an active request already pending, reject it to prioritize the newer one.
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete(false);
    }

    _activeCompleter = completer;
    state = state.copyWith(activeRequest: transfer);

    // Auto-dismiss after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (state.activeRequest?.id == transfer.id) {
        rejectRequest(transfer.id);
      }
    });

    return completer.future;
  }

  /// Accept the incoming file transfer request.
  void acceptRequest(String id) {
    if (state.activeRequest?.id == id) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(true);
      }

      final updatedTransfer = state.activeRequest!.copyWith(
        status: TransferStatus.transferring,
        progress: 0.0,
      );

      final newTransfers = Map<String, TransferModel>.from(state.activeTransfers);
      newTransfers[id] = updatedTransfer;

      state = state.copyWith(
        activeTransfers: newTransfers,
        clearActiveRequest: true,
      );
    }
  }

  /// Reject the incoming file transfer request.
  void rejectRequest(String id) {
    if (state.activeRequest?.id == id) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(false);
      }
      
      final rejectedTransfer = state.activeRequest!.copyWith(
        status: TransferStatus.rejected,
      );
      _ref.read(historyProvider.notifier).addTransfer(rejectedTransfer);
      
      state = state.copyWith(clearActiveRequest: true);
    }
  }

  /// Update the download progress of a running transfer.
  void updateProgress(String id, double progress) {
    final transfer = state.activeTransfers[id];
    if (transfer != null) {
      final newTransfers = Map<String, TransferModel>.from(state.activeTransfers);
      newTransfers[id] = transfer.copyWith(
        status: TransferStatus.transferring,
        progress: progress,
      );
      state = state.copyWith(activeTransfers: newTransfers);
    }
  }

  /// Mark the transfer as completed (success or failure) and trigger notification.
  void completeTransfer(String id, {required bool success, String? localPath}) {
    final transfer = state.activeTransfers[id];
    if (transfer != null) {
      final newTransfers = Map<String, TransferModel>.from(state.activeTransfers);
      final finalTransfer = transfer.copyWith(
        status: success ? TransferStatus.done : TransferStatus.failed,
        progress: success ? 1.0 : transfer.progress,
        localPath: localPath,
      );
      newTransfers[id] = finalTransfer;
      state = state.copyWith(activeTransfers: newTransfers);

      _ref.read(historyProvider.notifier).addTransfer(finalTransfer);

      if (success && localPath != null) {
        _ref.read(notificationServiceProvider).showTransferSuccess(
          transfer.fileName,
          localPath,
        );
      }
    }
  }
}

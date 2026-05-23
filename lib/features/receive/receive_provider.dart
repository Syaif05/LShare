import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/transfer_model.dart';
import '../../core/services/notification_service.dart';
import '../history/history_provider.dart';

class ReceiveState {
  final List<TransferModel>? activeRequestBatch;
  final Map<String, TransferModel> activeTransfers;

  const ReceiveState({
    this.activeRequestBatch,
    this.activeTransfers = const {},
  });

  TransferModel? get activeRequest => (activeRequestBatch != null && activeRequestBatch!.isNotEmpty)
      ? activeRequestBatch!.first
      : null;

  ReceiveState copyWith({
    List<TransferModel>? activeRequestBatch,
    Map<String, TransferModel>? activeTransfers,
    bool clearActiveRequest = false,
  }) {
    return ReceiveState(
      activeRequestBatch: clearActiveRequest ? null : (activeRequestBatch ?? this.activeRequestBatch),
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

  /// Handles an incoming transfer request batch by saving the completer and displaying a prompt.
  Future<bool> handleIncomingRequestBatch(List<TransferModel> transfers, Completer<bool> completer) async {
    // If there's an active request already pending, reject it to prioritize the newer one.
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete(false);
    }

    _activeCompleter = completer;
    state = state.copyWith(activeRequestBatch: transfers);

    // Auto-dismiss after 30 seconds
    final batchId = transfers.first.id;
    Future.delayed(const Duration(seconds: 30), () {
      if (state.activeRequestBatch != null &&
          state.activeRequestBatch!.isNotEmpty &&
          state.activeRequestBatch!.first.id == batchId) {
        rejectRequestBatch();
      }
    });

    return completer.future;
  }

  /// Legacy single request compatibility wrapper.
  Future<bool> handleIncomingRequest(TransferModel transfer, Completer<bool> completer) async {
    return handleIncomingRequestBatch([transfer], completer);
  }

  /// Accept the incoming batch transfer request.
  void acceptRequestBatch() {
    if (state.activeRequestBatch != null && state.activeRequestBatch!.isNotEmpty) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(true);
      }

      final newTransfers = Map<String, TransferModel>.from(state.activeTransfers);
      for (var transfer in state.activeRequestBatch!) {
        newTransfers[transfer.id] = transfer.copyWith(
          status: TransferStatus.transferring,
          progress: 0.0,
        );
      }

      state = state.copyWith(
        activeTransfers: newTransfers,
        clearActiveRequest: true,
      );
    }
  }

  /// Legacy single accept wrapper.
  void acceptRequest(String id) {
    acceptRequestBatch();
  }

  /// Reject the incoming batch transfer request.
  void rejectRequestBatch() {
    if (state.activeRequestBatch != null && state.activeRequestBatch!.isNotEmpty) {
      if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
        _activeCompleter!.complete(false);
      }
      
      for (var transfer in state.activeRequestBatch!) {
        final rejectedTransfer = transfer.copyWith(
          status: TransferStatus.rejected,
        );
        _ref.read(historyProvider.notifier).addTransfer(rejectedTransfer);
      }
      
      state = state.copyWith(clearActiveRequest: true);
    }
  }

  /// Legacy single reject wrapper.
  void rejectRequest(String id) {
    rejectRequestBatch();
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

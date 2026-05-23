// lib/features/send/progress_widget.dart
import 'package:flutter/material.dart';
import '../../core/models/transfer_model.dart';
import '../../shared/widgets/transfer_progress_bar.dart';

// Placeholder — akan diimplementasi di Fase 3
class ProgressWidget extends StatelessWidget {
  final TransferModel? transfer;

  const ProgressWidget({super.key, this.transfer});

  @override
  Widget build(BuildContext context) {
    if (transfer == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TransferProgressBar(transfer: transfer!),
    );
  }
}

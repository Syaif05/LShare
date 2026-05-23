import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/transfer_model.dart';

enum HistoryFilter { all, sent, received }

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter.all);

final historyLimitProvider = StateProvider<int>((ref) => 15);

final historyProvider = StateNotifierProvider<HistoryNotifier, List<TransferModel>>((ref) {
  return HistoryNotifier();
});

final filteredHistoryProvider = Provider<List<TransferModel>>((ref) {
  final history = ref.watch(historyProvider);
  final filter = ref.watch(historyFilterProvider);

  switch (filter) {
    case HistoryFilter.sent:
      return history.where((item) => item.isSent).toList();
    case HistoryFilter.received:
      return history.where((item) => !item.isSent).toList();
    case HistoryFilter.all:
      return history;
  }
});

final paginatedHistoryProvider = Provider<List<TransferModel>>((ref) {
  final filtered = ref.watch(filteredHistoryProvider);
  final limit = ref.watch(historyLimitProvider);
  return filtered.take(limit).toList();
});

final hasMoreHistoryProvider = Provider<bool>((ref) {
  final filteredCount = ref.watch(filteredHistoryProvider).length;
  final limit = ref.watch(historyLimitProvider);
  return filteredCount > limit;
});

class HistoryNotifier extends StateNotifier<List<TransferModel>> {
  static const String _prefKey = 'lshare_transfer_history';

  HistoryNotifier() : super([]) {
    loadHistory();
  }

  /// Loads the history list from SharedPreferences.
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_prefKey);
      if (jsonList != null) {
        state = jsonList
            .map((item) => TransferModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading transfer history: $e');
    }
  }

  /// Adds a transfer log to the list and persists it (caps at 100 items).
  Future<void> addTransfer(TransferModel transfer) async {
    final currentList = List<TransferModel>.from(state);
    
    // Remove duplicate ID if it exists (allows updating existing log status)
    currentList.removeWhere((item) => item.id == transfer.id);
    
    // Add to the top
    currentList.insert(0, transfer);

    // Limit to 100 items
    if (currentList.length > 100) {
      currentList.removeRange(100, currentList.length);
    }

    state = currentList;
    await _saveToPrefs(currentList);
  }

  /// Deletes a transfer log from history.
  Future<void> deleteTransfer(String id) async {
    final currentList = List<TransferModel>.from(state);
    currentList.removeWhere((item) => item.id == id);
    state = currentList;
    await _saveToPrefs(currentList);
  }

  /// Clears all transfer logs.
  Future<void> clearHistory() async {
    state = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (e) {
      print('Error clearing transfer history: $e');
    }
  }

  Future<void> _saveToPrefs(List<TransferModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((item) => jsonEncode(item.toJson())).toList();
      await prefs.setStringList(_prefKey, jsonList);
    } catch (e) {
      print('Error saving transfer history: $e');
    }
  }
}

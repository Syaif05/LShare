import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/transfer_model.dart';

enum HistoryFilter { all, sent, received }

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter.all);

final historyLimitProvider = StateProvider<int>((ref) => 15);

final historyProvider = StateNotifierProvider<HistoryNotifier, List<TransferModel>>((ref) {
  return HistoryNotifier();
});

enum HistorySort { newest, oldest }

final historySortProvider = StateProvider<HistorySort>((ref) => HistorySort.newest);
final historyFilterDeviceProvider = StateProvider<String?>((ref) => null);

final filteredHistoryProvider = Provider<List<TransferModel>>((ref) {
  final history = ref.watch(historyProvider);
  final typeFilter = ref.watch(historyFilterProvider);
  final deviceFilter = ref.watch(historyFilterDeviceProvider);
  final sort = ref.watch(historySortProvider);

  var result = List<TransferModel>.from(history);

  switch (typeFilter) {
    case HistoryFilter.sent:
      result = result.where((item) => item.isSent).toList();
      break;
    case HistoryFilter.received:
      result = result.where((item) => !item.isSent).toList();
      break;
    case HistoryFilter.all:
      break;
  }

  if (deviceFilter != null && deviceFilter.isNotEmpty && deviceFilter != 'Semua') {
    result = result.where((item) => item.isSent ? item.toDevice == deviceFilter : item.fromDevice == deviceFilter).toList();
  }

  if (sort == HistorySort.newest) {
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  } else {
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  return result;
});

// Model untuk merepresentasikan sebuah grup riwayat
class HistoryGroup {
  final String groupId;
  final List<TransferModel> items;

  HistoryGroup({required this.groupId, required this.items});

  DateTime get latestTimestamp => items.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
  bool get isSent => items.first.isSent;
  String get device => items.first.isSent ? items.first.toDevice : items.first.fromDevice;
  int get totalSize => items.fold(0, (sum, item) => sum + item.fileSize);
  bool get isCompleted => items.every((e) => e.status == TransferStatus.done || e.status == TransferStatus.failed || e.status == TransferStatus.rejected);
  int get successCount => items.where((e) => e.status == TransferStatus.done).length;
}

final groupedHistoryProvider = Provider<List<HistoryGroup>>((ref) {
  final filtered = ref.watch(filteredHistoryProvider);
  
  final Map<String, List<TransferModel>> groupedMap = {};
  for (var item in filtered) {
    final key = item.groupId;
    groupedMap.putIfAbsent(key, () => []).add(item);
  }

  final groups = groupedMap.entries.map((e) => HistoryGroup(groupId: e.key, items: e.value)).toList();
  
  // Sort again to ensure groups are ordered by timestamp based on the selected sort mode
  final sort = ref.watch(historySortProvider);
  if (sort == HistorySort.newest) {
    groups.sort((a, b) => b.latestTimestamp.compareTo(a.latestTimestamp));
  } else {
    groups.sort((a, b) => a.latestTimestamp.compareTo(b.latestTimestamp));
  }
  
  return groups;
});

final paginatedGroupedHistoryProvider = Provider<List<HistoryGroup>>((ref) {
  final grouped = ref.watch(groupedHistoryProvider);
  final limit = ref.watch(historyLimitProvider);
  return grouped.take(limit).toList();
});

final hasMoreGroupedHistoryProvider = Provider<bool>((ref) {
  final groupedCount = ref.watch(groupedHistoryProvider).length;
  final limit = ref.watch(historyLimitProvider);
  return groupedCount > limit;
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
    
    // Backup to Supabase
    _backupToSupabase(transfer);
  }

  Future<void> _backupToSupabase(TransferModel transfer) async {
    try {
      // Only backup completed transfers (done, failed, rejected)
      if (transfer.status == TransferStatus.transferring || transfer.status == TransferStatus.pending) return;

      final supabase = Supabase.instance.client;
      
      // UPSERT using id as primary key
      await supabase.from('transfers').upsert({
        'id': transfer.id,
        'group_id': transfer.groupId,
        'file_name': transfer.fileName,
        'file_size': transfer.fileSize,
        'from_device': transfer.fromDevice,
        'to_device': transfer.toDevice,
        'status': transfer.status.name,
        'is_sent': transfer.isSent,
        'timestamp': transfer.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error backing up transfer to Supabase: $e');
    }
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

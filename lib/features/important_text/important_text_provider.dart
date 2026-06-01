import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/clipboard_model.dart';
import '../settings/settings_provider.dart';

// Provides the saved PIN (null if no PIN is set)
final importantTextPinProvider = StateProvider<String?>((ref) => null);

// Initialize PIN from SharedPreferences
Future<void> initImportantTextPin(WidgetRef ref, SharedPreferences prefs) async {
  final pin = prefs.getString('important_text_pin');
  ref.read(importantTextPinProvider.notifier).state = pin;
}

// History of important texts
final importantTextHistoryProvider = StateProvider<List<ClipboardModel>>((ref) => []);
final importantTextLoadingProvider = StateProvider<bool>((ref) => false);
final importantTextErrorProvider = StateProvider<String?>((ref) => null);

// Provide a service to manage important texts
final importantTextServiceProvider = Provider<ImportantTextService>((ref) {
  return ImportantTextService(ref);
});

class ImportantTextService {
  final Ref _ref;
  RealtimeChannel? _channel;

  ImportantTextService(this._ref);

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAndSubscribe() async {
    final client = _supabase;
    if (client == null) {
      _ref.read(importantTextErrorProvider.notifier).state = 'Client Supabase belum diinisialisasi';
      return;
    }

    _ref.read(importantTextLoadingProvider.notifier).state = true;
    _ref.read(importantTextErrorProvider.notifier).state = null;

    try {
      // Fetch initial data
      final initialData = await client.from('important_texts').select().order('created_at', ascending: false).limit(50);
      final currentHistory = initialData.map((e) => ClipboardModel(
        text: (e['text'] ?? '') as String,
        fromDevice: (e['device_name'] ?? 'Unknown Device') as String,
        timestamp: e['created_at'] != null 
            ? DateTime.parse(e['created_at'] as String).toLocal() 
            : DateTime.now(),
        isLocked: true, // Always locked visually
      )).toList();
      
      _ref.read(importantTextHistoryProvider.notifier).state = currentHistory;

      // Subscribe to changes
      if (_channel == null) {
        _channel = client.channel('public:important_texts');
        _channel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'important_texts',
          callback: (payload) {
            _handleIncomingData();
          },
        ).subscribe();
      }
    } catch (e) {
      _ref.read(importantTextErrorProvider.notifier).state = 'Gagal memuat teks penting: $e';
    } finally {
      _ref.read(importantTextLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _handleIncomingData() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final data = await client.from('important_texts').select().order('created_at', ascending: false).limit(50);
      final currentHistory = data.map((e) => ClipboardModel(
        text: (e['text'] ?? '') as String,
        fromDevice: (e['device_name'] ?? 'Unknown Device') as String,
        timestamp: e['created_at'] != null 
            ? DateTime.parse(e['created_at'] as String).toLocal() 
            : DateTime.now(),
        isLocked: true,
      )).toList();
      _ref.read(importantTextHistoryProvider.notifier).state = currentHistory;
    } catch (_) {}
  }

  Future<void> addText(String text) async {
    final client = _supabase;
    if (client == null) {
      _ref.read(importantTextErrorProvider.notifier).state = 'Client Supabase belum diinisialisasi';
      return;
    }

    final senderName = _ref.read(deviceNameProvider);
    try {
      await client.from('important_texts').insert({
        'text': text,
        'device_name': senderName,
      });
      // Will be reloaded by realtime subscription
    } catch (e) {
      _ref.read(importantTextErrorProvider.notifier).state = 'Gagal menyimpan: $e';
    }
  }

  Future<void> deleteText(String text, String deviceName) async {
    final client = _supabase;
    if (client == null) return;
    try {
      await client.from('important_texts')
          .delete()
          .eq('text', text)
          .eq('device_name', deviceName);
    } catch (e) {
      _ref.read(importantTextErrorProvider.notifier).state = 'Gagal menghapus: $e';
    }
  }

  void dispose() {
    if (_channel != null) {
      _supabase?.removeChannel(_channel!);
      _channel = null;
    }
  }
}

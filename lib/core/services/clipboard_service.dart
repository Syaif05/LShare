import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clipboard_model.dart';
import '../../features/clipboard/clipboard_provider.dart';
import '../../features/settings/settings_provider.dart';

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(ref);
  
  // Listen for clipboard sync enabled changes
  ref.listen<bool>(clipboardSyncEnabledProvider, (previous, next) {
    if (next) {
      service.startClipboardMonitoring();
      service.connectToSupabase();
    } else {
      service.stopClipboardMonitoring();
      service.disconnectSupabase();
    }
  });
  
  return service;
});

class ClipboardService {
  final Ref _ref;
  
  Timer? _clipboardTimer;
  String _lastClipboardText = '';
  
  RealtimeChannel? _channel;

  ClipboardService(this._ref);

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null; // Not initialized
    }
  }

  bool get isRunning => _channel != null;

  Future<void> startService() async {
    final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
    if (syncEnabled) {
      await connectToSupabase();
      startClipboardMonitoring();
    }
  }

  Future<void> stopService() async {
    stopClipboardMonitoring();
    await disconnectSupabase();
    print('Clipboard Sync Service stopped');
  }

  void stopClipboardMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  void startClipboardMonitoring() {
    _clipboardTimer?.cancel();
    _clipboardTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final syncEnabled = _ref.read(clipboardSyncEnabledProvider);
      if (!syncEnabled) return;

      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text != null && text.isNotEmpty && text != _lastClipboardText) {
          _lastClipboardText = text;
          _handleLocalClipboardChanged(text);
        }
      } catch (_) {
        // Occasionally locked by system
      }
    });
  }

  Future<void> reconnect() async {
    await disconnectSupabase();
    await connectToSupabase();
  }

  Future<void> connectToSupabase() async {
    final client = _supabase;
    if (client == null) {
      _ref.read(clipboardErrorProvider.notifier).state = 'Client Supabase belum diinisialisasi';
      return;
    }
    if (_channel != null) return;

    _ref.read(clipboardErrorProvider.notifier).state = null;

    try {
      _channel = client.channel('public:clipboards');
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'clipboards',
        callback: (payload) {
          _handleIncomingSupabaseData(payload.newRecord);
        },
      ).subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _ref.read(clipboardConnectionsProvider.notifier).state = ['Supabase Cloud'];
          _ref.read(clipboardErrorProvider.notifier).state = null;
          print('Connected to Supabase Realtime');
        } else if (status == RealtimeSubscribeStatus.closed || status == RealtimeSubscribeStatus.channelError) {
          _ref.read(clipboardConnectionsProvider.notifier).state = [];
          if (error != null) {
            _ref.read(clipboardErrorProvider.notifier).state = 'Realtime error: $error';
          } else {
            _ref.read(clipboardErrorProvider.notifier).state = 'Koneksi Realtime terputus';
          }
        }
      });
      
      // Auto-delete records older than 7 days that are not locked
      try {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        await client.from('clipboards')
            .delete()
            .lt('created_at', sevenDaysAgo)
            .eq('is_locked', false);
      } catch (e) {
        print('Error auto-deleting old clipboards: $e');
      }

      // Fetch initial data
      final initialData = await client.from('clipboards').select().order('created_at', ascending: false).limit(10);
      final currentHistory = initialData.map((e) => ClipboardModel(
        text: (e['text'] ?? '') as String,
        fromDevice: (e['device_name'] ?? 'Unknown Device') as String,
        timestamp: e['created_at'] != null 
            ? DateTime.parse(e['created_at'] as String).toLocal() 
            : DateTime.now(),
        isLocked: e['is_locked'] as bool? ?? false,
      )).toList();
      
      _ref.read(clipboardHistoryProvider.notifier).state = currentHistory;
      if (currentHistory.isNotEmpty) {
        _lastClipboardText = currentHistory.first.text;
      }
    } catch (e) {
      _channel = null;
      _ref.read(clipboardErrorProvider.notifier).state = 'Gagal memuat data: $e';
      print('Supabase connection error: $e');
    }
  }

  Future<void> toggleLock(ClipboardModel item) async {
    final client = _supabase;
    if (client == null) return;
    try {
      // Optimitic local update
      final currentHistory = _ref.read(clipboardHistoryProvider);
      final updatedHistory = currentHistory.map((e) {
        if (e.text == item.text && e.fromDevice == item.fromDevice) {
          return e.copyWith(isLocked: !e.isLocked);
        }
        return e;
      }).toList();
      _ref.read(clipboardHistoryProvider.notifier).state = updatedHistory;

      // Remote update
      await client.from('clipboards')
          .update({'is_locked': !item.isLocked})
          .eq('text', item.text)
          .eq('device_name', item.fromDevice);
    } catch (e) {
      print('Error updating lock status: $e');
      // Revert if error? For now just log
    }
  }

  Future<void> disconnectSupabase() async {
    if (_channel != null) {
      await _supabase?.removeChannel(_channel!);
      _channel = null;
    }
    _ref.read(clipboardConnectionsProvider.notifier).state = [];
  }

  Future<void> _handleLocalClipboardChanged(String text) async {
    final senderName = _ref.read(deviceNameProvider);
    final model = ClipboardModel(
      text: text,
      fromDevice: senderName,
      timestamp: DateTime.now(),
    );

    // Update local history immediately
    final currentHistory = _ref.read(clipboardHistoryProvider);
    if (currentHistory.isEmpty || currentHistory.first.text != text) {
      _ref.read(clipboardHistoryProvider.notifier).state = [
        model,
        ...currentHistory.take(9),
      ];
    }

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('clipboards').insert({
          'text': text,
          'device_name': senderName,
          'platform': Platform.operatingSystem,
          'is_locked': false,
        });
        _ref.read(clipboardErrorProvider.notifier).state = null; // Clear error if success
      } catch (e) {
        print('Error inserting to Supabase: $e');
        _ref.read(clipboardErrorProvider.notifier).state = 'Gagal menyimpan ke cloud: $e';
      }
    } else {
      _ref.read(clipboardErrorProvider.notifier).state = 'Supabase belum diinisialisasi';
    }
  }

  void _handleIncomingSupabaseData(Map<String, dynamic> data) {
    final text = (data['text'] ?? '') as String;
    final deviceName = (data['device_name'] ?? 'Unknown Device') as String;
    
    // Ignore if it came from our own device
    if (deviceName == _ref.read(deviceNameProvider)) return;
    
    if (text.isEmpty || text == _lastClipboardText) return;
    _lastClipboardText = text;

    // Update local system clipboard
    Clipboard.setData(ClipboardData(text: text));

    final model = ClipboardModel(
      text: text,
      fromDevice: deviceName,
      timestamp: data['created_at'] != null 
          ? DateTime.parse(data['created_at'] as String).toLocal() 
          : DateTime.now(),
      isLocked: data['is_locked'] as bool? ?? false,
    );

    final currentHistory = _ref.read(clipboardHistoryProvider);
    if (currentHistory.isEmpty || currentHistory.first.text != text) {
      _ref.read(clipboardHistoryProvider.notifier).state = [
        model,
        ...currentHistory.take(9),
      ];
    }
  }
}

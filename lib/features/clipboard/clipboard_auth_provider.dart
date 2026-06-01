import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/crypto_utils.dart';
import '../../core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final clipboardAuthStatusProvider = StateProvider<bool>((ref) => false);
final clipboardDecryptedUrlProvider = StateProvider<String?>((ref) => null);
final clipboardDecryptedKeyProvider = StateProvider<String?>((ref) => null);

Future<void> initClipboardAuth(dynamic ref, SharedPreferences prefs) async {
  final savedPin = prefs.getString('clipboard_master_pin');
  if (savedPin != null) {
    if (await _tryUnlock(ref, savedPin)) return;
  }
  
  final viralUrl = prefs.getString('viral_url');
  final viralKey = prefs.getString('viral_key');
  if (viralUrl != null && viralKey != null) {
    await unlockWithCredentials(ref, viralUrl, viralKey);
  }
}

Future<bool> _tryUnlock(dynamic ref, String pin) async {
  final url = CryptoUtils.decrypt(kEncryptedSupabaseUrl, pin);
  final key = CryptoUtils.decrypt(kEncryptedSupabaseAnonKey, pin);
  
  if (url != null && key != null && url.startsWith('http')) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
    } catch (_) {
      // Ignore if already initialized
    }
    ref.read(clipboardDecryptedUrlProvider.notifier).state = url;
    ref.read(clipboardDecryptedKeyProvider.notifier).state = key;
    ref.read(clipboardAuthStatusProvider.notifier).state = true;
    return true;
  }
  return false;
}

Future<bool> unlockWithPin(dynamic ref, String pin) async {
  final success = await _tryUnlock(ref, pin);
  if (success) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clipboard_master_pin', pin);
  }
  return success;
}

Future<void> unlockWithCredentials(dynamic ref, String url, String key) async {
  try {
    await Supabase.initialize(url: url, anonKey: key);
  } catch (_) {
    // Ignore if already initialized
  }
  ref.read(clipboardDecryptedUrlProvider.notifier).state = url;
  ref.read(clipboardDecryptedKeyProvider.notifier).state = key;
  ref.read(clipboardAuthStatusProvider.notifier).state = true;
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('viral_url', url);
  await prefs.setString('viral_key', key);
}

Future<void> lockClipboard(dynamic ref) async {
  ref.read(clipboardAuthStatusProvider.notifier).state = false;
  ref.read(clipboardDecryptedUrlProvider.notifier).state = null;
  ref.read(clipboardDecryptedKeyProvider.notifier).state = null;
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('clipboard_master_pin');
  await prefs.remove('viral_url');
  await prefs.remove('viral_key');
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoUtils {
  static enc.Key _deriveKey(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  static String encrypt(String plainText, String pin) {
    final key = _deriveKey(pin);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String? decrypt(String cipherText, String pin) {
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final key = _deriveKey(pin);
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null; // Return null if decryption fails (wrong PIN)
    }
  }
}

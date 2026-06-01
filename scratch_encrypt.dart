import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

void main() {
  final pin = '3209142305050001';
  final url = 'https://apjeccqvqyucnwgyxvhb.supabase.co';
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFwamVjY3F2cXl1Y253Z3l4dmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NTU1MDYsImV4cCI6MjA5NTUzMTUwNn0.1t1buwgl7Cpe63GbKi-AEVznmx-dB7Fa9VFcQE0PQTY';

  final bytes = utf8.encode(pin);
  final digest = sha256.convert(bytes);
  final key = enc.Key(Uint8List.fromList(digest.bytes));

  final iv1 = enc.IV.fromSecureRandom(16);
  final encrypter1 = enc.Encrypter(enc.AES(key));
  final encUrl = '${iv1.base64}:${encrypter1.encrypt(url, iv: iv1).base64}';

  final iv2 = enc.IV.fromSecureRandom(16);
  final encrypter2 = enc.Encrypter(enc.AES(key));
  final encKey = '${iv2.base64}:${encrypter2.encrypt(anonKey, iv: iv2).base64}';

  print('ENC_URL: $encUrl');
  print('ENC_KEY: $encKey');
}

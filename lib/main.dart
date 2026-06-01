// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase if keys are provided
  if (kSupabaseUrl != 'YOUR_SUPABASE_URL' && kSupabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') {
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
  } else {
    print('WARNING: Supabase URL and Anon Key are not set. Clipboard Sync will not work.');
  }

  runApp(
    const ProviderScope(
      child: LShareApp(),
    ),
  );
}

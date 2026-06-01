// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase will be initialized later when the user enters the PIN or gets keys virally.
  
  runApp(
    const ProviderScope(
      child: LShareApp(),
    ),
  );
}

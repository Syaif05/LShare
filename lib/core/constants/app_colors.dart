// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (Material 3)
  static const Color primary = Color(0xFF1E88E5);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFE3F2FD);
  static const Color onPrimaryContainer = Color(0xFF003258);

  // Secondary palette
  static const Color secondary = Color(0xFF0D47A1);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFD6E4FF);
  static const Color onSecondaryContainer = Color(0xFF001945);

  // Surface / Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEF2F7);
  static const Color onBackground = Color(0xFF1A1C1E);
  static const Color onSurface = Color(0xFF1A1C1E);

  // Status colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFFCECEA);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningContainer = Color(0xFFFFF3E0);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF44474E);
  static const Color textDisabled = Color(0xFFAAADB5);

  // Misc
  static const Color divider = Color(0xFFE0E3E9);
  static const Color outline = Color(0xFFBDC1CC);
}

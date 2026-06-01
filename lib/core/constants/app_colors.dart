// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Neo-Brutalism Core Palette
  static const Color paperWhite = Color(0xFFFDFDFD);
  static const Color acidYellow = Color(0xFFE5FF00);
  static const Color neoBlack = Color(0xFF1A1A1A);
  
  // Optional Accents (if needed for secondary actions)
  static const Color neoPink = Color(0xFFFF90E8);
  static const Color neoBlue = Color(0xFF90E8FF);
  static const Color neoGreen = Color(0xFF23C15D);

  // Semantic Mappings
  static const Color primary = neoBlack;
  static const Color onPrimary = acidYellow;
  static const Color primaryContainer = acidYellow;
  static const Color onPrimaryContainer = neoBlack;

  static const Color secondary = Color(0xFF4A4A4A);
  static const Color onSecondary = paperWhite;
  static const Color secondaryContainer = Color(0xFFE0E0E0);
  static const Color onSecondaryContainer = neoBlack;

  // Surface / Background
  static const Color background = paperWhite;
  static const Color surface = paperWhite;
  static const Color surfaceVariant = Color(0xFFF0F0F0);
  static const Color onBackground = neoBlack;
  static const Color onSurface = neoBlack;

  // Status colors
  static const Color success = neoGreen;
  static const Color successContainer = Color(0xFFD4F8E2);
  static const Color error = Color(0xFFFF4D4D);
  static const Color errorContainer = Color(0xFFFFD9D9);
  static const Color warning = Color(0xFFFFB800);
  static const Color warningContainer = Color(0xFFFFF1CC);

  // Text colors
  static const Color textPrimary = neoBlack;
  static const Color textSecondary = Color(0xFF555555);
  static const Color textDisabled = Color(0xFFAAAAAA);

  // Misc
  static const Color divider = neoBlack;
  static const Color outline = neoBlack;
}

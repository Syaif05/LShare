// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.neoPink,
      onTertiary: AppColors.neoBlack,
      tertiaryContainer: AppColors.neoBlue,
      onTertiaryContainer: AppColors.neoBlack,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: Color(0xFF410002),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.neoBlack,
      onInverseSurface: AppColors.paperWhite,
      inversePrimary: AppColors.acidYellow,
    );

    final textTheme = GoogleFonts.outfitTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
      ),
    );

    final neoBorder = BorderSide(color: AppColors.neoBlack, width: 2.0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: false,
        // Bottom border for AppBar
        shape: Border(bottom: neoBorder),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: neoBorder,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neoBlack,
          foregroundColor: AppColors.acidYellow,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neoBlack,
          backgroundColor: AppColors.paperWhite,
          side: neoBorder,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acidYellow,
          foregroundColor: AppColors.neoBlack,
          side: neoBorder,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.acidYellow,
        foregroundColor: AppColors.neoBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: neoBorder,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.acidYellow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: neoBorder,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.neoBlack);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.neoBlack,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          );
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.acidYellow,
        labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: neoBorder,
        ),
        checkmarkColor: AppColors.neoBlack,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.neoBlack,
        thickness: 2,
        space: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paperWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: neoBorder,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: neoBorder,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neoBlack, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.neoBlack, fontWeight: FontWeight.w800),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neoBlack,
        contentTextStyle: GoogleFonts.outfit(color: AppColors.acidYellow, fontSize: 14, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.acidYellow, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.neoBlack;
          return AppColors.neoBlack;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.acidYellow;
          return AppColors.paperWhite;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.neoBlack),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.paperWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppColors.neoBlack, width: 2),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paperWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: neoBorder,
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.neoBlack,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.neoBlack,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

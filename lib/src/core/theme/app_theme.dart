import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_spacing.dart';

final appThemeProvider = Provider<AppTheme>((ref) {
  return AppTheme();
});

/// Gokulshree unified theme — **dark only**.
///
/// Rules from the brand guide:
///  • Background is always Ink Navy 900
///  • Gold is accent/CTA ONLY, never full-surface background
///  • Fonts: Fraunces (display), Manrope (body), JetBrains Mono (codes)
///  • Never use Poppins or Inter
class AppTheme {
  // Legacy accessors — use AppColors directly in new code.
  static const Color primaryColor = AppColors.inkNavy600;
  static const Color secondaryColor = AppColors.goldCta;
  static const Color accentColor = AppColors.goldCta;
  static const Color backgroundColor = AppColors.inkNavy900;
  static const Color errorColor = AppColors.danger;

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ─── Colour scheme ───
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldCta,
        onPrimary: AppColors.inkNavy900,
        secondary: AppColors.goldShine,
        onSecondary: AppColors.inkNavy900,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.inkNavy800,
        onSurface: AppColors.textPrimary,
      ),

      scaffoldBackgroundColor: AppColors.inkNavy900,
      canvasColor: AppColors.inkNavy900,
      cardColor: AppColors.inkNavy800,
      dividerColor: AppColors.divider,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.inkNavy900,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ─── Text theme (Manrope base) ───
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.goldCta,
            ),
            displayMedium: GoogleFonts.fraunces(
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
            headlineLarge: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            headlineMedium: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            bodyLarge: GoogleFonts.manrope(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
            bodyMedium: GoogleFonts.manrope(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
            labelLarge: GoogleFonts.manrope(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),

      // ─── Elevated button (Gold CTA) ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldCta,
          foregroundColor: AppColors.inkNavy900,
          disabledBackgroundColor: AppColors.inkNavy600,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),

      // ─── Outlined button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldCta,
          side: const BorderSide(color: AppColors.goldCta, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // ─── Text button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldCta,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input decoration ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.inputFocusBorder,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: GoogleFonts.manrope(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.manrope(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        color: AppColors.inkNavy800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Bottom nav bar ───
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.inkNavy800,
        selectedItemColor: AppColors.goldCta,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.inkNavy700,
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkNavy700,
        contentTextStyle: GoogleFonts.manrope(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ─── Progress indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.goldCta,
        linearTrackColor: AppColors.inkNavy600,
        circularTrackColor: AppColors.inkNavy600,
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  // Keep old accessor for backwards compatibility during migration.
  ThemeData get lightTheme => darkTheme;
}

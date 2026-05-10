import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';

/// Gokulshree type-scale — Fraunces (display, italic) + Manrope (body).
/// Brand guide rule: **never** use Inter or Poppins.
abstract final class AppTypography {
  // ─── Display — Fraunces Italic ───
  static TextStyle displayLg = GoogleFonts.fraunces(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: AppColors.goldCta,
    height: 1.2,
  );

  static TextStyle displayMd = GoogleFonts.fraunces(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle displaySm = GoogleFonts.fraunces(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Headings — Manrope Bold / SemiBold ───
  static TextStyle headingLg = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headingMd = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle headingSm = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── Body — Manrope Regular ───
  static TextStyle bodyLg = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMd = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySm = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ─── Labels — Manrope Medium ───
  static TextStyle labelLg = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle labelMd = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static TextStyle labelSm = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ─── Mono — JetBrains Mono (registration numbers, OTPs, codes) ───
  static TextStyle mono = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}

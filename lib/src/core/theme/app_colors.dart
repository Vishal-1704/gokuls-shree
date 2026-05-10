import 'package:flutter/material.dart';

/// Gokulshree brand colour tokens — standardised from brand_guide.html.
/// Dark-only palette. Gold is accent ONLY, never background.
abstract final class AppColors {
  // ─── Ink Navy scale ───
  static const Color inkNavy900 = Color(0xFF070D18); // scaffold bg
  static const Color inkNavy800 = Color(0xFF0E1E33); // card bg
  static const Color inkNavy700 = Color(0xFF152D4D); // elevated surfaces
  static const Color inkNavy600 = Color(0xFF1A3A5C); // borders / dividers
  static const Color inkNavy500 = Color(0xFF243D60); // subtle accents

  // ─── Gold scale ───
  static const Color goldCta = Color(0xFFF5CC45); // primary CTA
  static const Color goldShine = Color(0xFFFDE380); // hover / active
  static const Color goldDeep = Color(0xFFA67B00); // text on gold bg

  // ─── Semantic ───
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted = Color(0xFF475569); // slate-600

  // ─── Surface / misc ───
  static const Color surfaceCard = inkNavy800;
  static const Color surfaceElevated = inkNavy700;
  static const Color divider = inkNavy600;
  static const Color inputFill = Color(0xFF101828);
  static const Color inputBorder = inkNavy600;
  static const Color inputFocusBorder = goldCta;

  // ─── Chip colours ───
  static const Color chipPaidBg = Color(0xFF052E16); // success bg tint
  static const Color chipPaidFg = success;
  static const Color chipPendingBg = Color(0xFF451A03); // warning bg tint
  static const Color chipPendingFg = warning;
  static const Color chipOverdueBg = Color(0xFF450A0A); // danger bg tint
  static const Color chipOverdueFg = danger;
}

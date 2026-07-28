import 'package:flutter/material.dart';

/// Modern Cyber Cyan, Electric Indigo & Emerald color palette.
/// Replaces legacy Navy & Yellow with ultra-sleek dark mode glassmorphism.
abstract final class AppColors {
  // ─── Main Slate scale (Light Mode) ───
  static const Color inkNavy900 = Color(0xFFF8FAFC); // Very light grey (slate-50) scaffold bg
  static const Color inkNavy800 = Color(0xFFFFFFFF); // White card bg
  static const Color inkNavy700 = Color(0xFFF1F5F9); // Elevated slate surfaces
  static const Color inkNavy600 = Color(0xFFE2E8F0); // Glass borders / dividers (slate-200)
  static const Color inkNavy500 = Color(0xFFCBD5E1); // Subtle accents (slate-300)

  // ─── Sky Blue accents ───
  static const Color goldCta = Color(0xFF0EA5E9); // Primary CTA (Sky Blue 500)
  static const Color goldShine = Color(0xFF38BDF8); // Hover / active (Sky Blue 400)
  static const Color goldDeep = Color(0xFF0284C7); // Deep Blue text (Sky Blue 600)

  // ─── Additional Gradients & Accents ───
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color primaryIndigo = Color(0xFF6366F1);
  static const Color emeraldMint = Color(0xFF10B981);

  // ─── Semantic ───
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Text (Light Mode) ───
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // ─── Surface / misc ───
  static const Color surfaceCard = inkNavy800;
  static const Color surfaceElevated = inkNavy700;
  static const Color divider = inkNavy600;
  static const Color divider10 = Color(0x1AE2E8F0); // 10% opacity divider
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color inputBorder = inkNavy600;
  static const Color inputFocusBorder = goldCta;

  // ─── Chip colours ───
  static const Color chipPaidBg = Color(0xFFD1FAE5); // emerald bg tint (Light)
  static const Color chipPaidFg = Color(0xFF065F46); // emerald fg tint (Dark)
  static const Color chipPendingBg = Color(0xFFFEF3C7); // warning bg tint (Light)
  static const Color chipPendingFg = Color(0xFF92400E); // warning fg tint (Dark)
  static const Color chipOverdueBg = Color(0xFFFEE2E2); // danger bg tint (Light)
  static const Color chipOverdueFg = Color(0xFF991B1B); // danger fg tint (Dark)
}

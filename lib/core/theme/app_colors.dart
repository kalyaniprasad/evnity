import 'package:flutter/material.dart';

/// Evnity Design System — Color Tokens
abstract class AppColors {
  // ── Primary ──────────────────────────────────────────────────────────────
  static const primary = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B60D4);
  static const primaryDark = Color(0xFF1A3697);
  static const primarySurface = Color(0xFFEFF4FF);
  static const primaryMuted = Color(0xFF93AEED);
  static const primaryBorder = Color(0xFFBFD0F5);

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8FAFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5FB);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);
  static const textDisabled = Color(0xFFCBD5E1);

  // ── Border & Divider ─────────────────────────────────────────────────────
  static const divider = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const error = Color(0xFFDC2626);
  static const errorSurface = Color(0xFFFEF2F2);
  static const success = Color(0xFF16A34A);
  static const successSurface = Color(0xFFF0FDF4);
  static const warning = Color(0xFFDC2626);
  // static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFFFBEB);

  // ── Onboarding Page Accents ───────────────────────────────────────────────
  static const page1IconBg = Color(0xFFEFF4FF);
  static const page1Icon = Color(0xFF1E40AF);
  static const page2IconBg = Color(0xFFF0FDF4);
  static const page2Icon = Color(0xFF16A34A);
  static const page3IconBg = Color(0xFFFFF7ED);
  static const page3Icon = Color(0xFFEA580C);

  // ── Social ───────────────────────────────────────────────────────────────
  static const googleBlue = Color(0xFF4285F4);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC05);
  static const googleGreen = Color(0xFF34A853);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static const cardShadow = Color(0x0F1E40AF);
  static const shadowLight = Color(0x08000000);
  static const shadowMedium = Color(0x14000000);

  // ── Category Colors ──────────────────────────────────────────────────────
  static const categoryTechnical  = Color(0xFF1E40AF); // = primary
  static const categoryCultural   = Color(0xFF7C3AED);
  static const categorySports     = Color(0xFF16A34A); // = success
  static const categoryWorkshop   = Color(0xFFD97706); // = warning
  static const categorySeminar    = Color(0xFFDB2777);
  static const categoryCulturalBg = Color(0xFFF5F3FF);
  static const categorySeminarBg  = Color(0xFFFDF2F8);
}

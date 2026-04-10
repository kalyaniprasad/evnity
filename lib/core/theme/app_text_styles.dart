import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Evnity Design System — Typography
abstract class AppTextStyles {
  // ── Display ──────────────────────────────────────────────────────────────
  static TextStyle get displayXL => GoogleFonts.dmSans(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle get displayL => GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle get displayM => GoogleFonts.dmSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Headings ─────────────────────────────────────────────────────────────
  static TextStyle get headingXL => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get headingL => GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get headingM => GoogleFonts.dmSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.35,
  );

  // ── Body ─────────────────────────────────────────────────────────────────
  static TextStyle get bodyL => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.65,
  );

  static TextStyle get bodyM => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static TextStyle get bodyS => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelL => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get labelM => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get labelS => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  // ── Caption ──────────────────────────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  // ── App Name / Brand ─────────────────────────────────────────────────────
  static TextStyle get brandName => GoogleFonts.dmSans(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -1.2,
  );

  static TextStyle get brandTagline => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.3,
  );
}

import 'package:flutter/material.dart';

/// Paleta de color institucional SENA usada en todo ParkU.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF39A900);
  static const Color primaryDark = Color(0xFF2D7D00);
  static const Color primarySoft = Color(0xFFEAF7E6);
  static const Color primarySoftBorder = Color(0xFFC5E0AD);

  static const Color background = Color(0xFFF5F7F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color loginBackground = Color(0xFFE7ECEE);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textPlaceholder = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F4);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerSoftBorder = Color(0xFFFECACA);
  static const Color dangerDark = Color(0xFF7F1D1D);
  static const Color dangerDarker = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF16A34A);

  static const Color neutralSoft = Color(0xFFF1F5F9);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );
}

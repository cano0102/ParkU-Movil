import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Estilos de texto reutilizables. Montserrat para texto general,
/// Roboto Mono para placas y valores numéricos (igual que el diseño).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle plate({double size = 26, Color color = AppColors.textPrimary}) {
    return GoogleFonts.robotoMono(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: size * 0.05,
    );
  }

  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w700, Color color = AppColors.textSecondary}) {
    return GoogleFonts.robotoMono(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle heading1 = _base(size: 34, weight: FontWeight.w900, letterSpacing: -0.5);
  static TextStyle heading2 = _base(size: 24, weight: FontWeight.w900, letterSpacing: -0.3);
  static TextStyle heading3 = _base(size: 20, weight: FontWeight.w900, letterSpacing: -0.2);

  static TextStyle title = _base(size: 17, weight: FontWeight.w800);
  static TextStyle body = _base(size: 15, weight: FontWeight.w600);
  static TextStyle bodyBold = _base(size: 15, weight: FontWeight.w800);

  static TextStyle caption = _base(size: 12, weight: FontWeight.w700, color: AppColors.textMuted);
  static TextStyle overline = _base(
    size: 12,
    weight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );

  static TextStyle small = _base(size: 11, weight: FontWeight.w700, color: AppColors.textPlaceholder);
  static TextStyle label = _base(size: 12, weight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.6);
}

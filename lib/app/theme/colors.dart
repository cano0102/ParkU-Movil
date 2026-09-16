import 'package:flutter/material.dart';

/// Paleta de color institucional SENA usada en todo ParkU.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF39A900);
  static const Color primaryDark = Color(0xFF2D7D00);
  static const Color primaryDeep = Color(0xFF1F5C00);
  static const Color primaryLight = Color(0xFF5BC236);
  static const Color primarySoft = Color(0xFFEAF7E6);
  static const Color primarySoftBorder = Color(0xFFC5E0AD);
  static const Color primaryAccent = Color(0xFFB3E6A1);

  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color loginBackground = Color(0xFFEDF1F3);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textPlaceholder = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE6EAF0);
  static const Color divider = Color(0xFFEEF2F4);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerSoftBorder = Color(0xFFFECACA);
  static const Color dangerDark = Color(0xFF7F1D1D);
  static const Color dangerDarker = Color(0xFFB91C1C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);

  static const Color neutralSoft = Color(0xFFF1F5F9);

  // Superficies oscuras (mapa del parqueadero, cámara).
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A2027);
  static const Color darkSurfaceRaised = Color(0xFF222A33);
  static const Color darkBorder = Color(0xFF2A3038);
  static const Color darkMuted = Color(0xFF94A3B8);

  // Sombras (tono azul-navy muy tenue para no ensuciar el verde).
  static const Color shadow = Color(0x120F172A);
  static const Color shadowSoft = Color(0x0A0F172A);
  static const Color primaryShadowColor = Color(0x5239A900);
  static const Color dangerShadowColor = Color(0x47EF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF47B90F), primary, primaryDark],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), danger, Color(0xFFC62828)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Sombra estándar de las tarjetas blancas sobre el fondo gris.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: shadow, blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: shadowSoft, blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Sombra de color para botones/superficies primarias.
  static const List<BoxShadow> primaryShadow = [
    BoxShadow(color: primaryShadowColor, blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> dangerShadow = [
    BoxShadow(color: dangerShadowColor, blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// Sombra hacia arriba para barras fijas en la parte inferior.
  static const List<BoxShadow> topShadow = [
    BoxShadow(color: shadow, blurRadius: 24, offset: Offset(0, -6)),
  ];
}

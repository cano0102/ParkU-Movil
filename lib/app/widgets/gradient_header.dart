import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

/// Cabecera con degradado institucional, esquinas inferiores redondeadas
/// y unos círculos decorativos muy tenues que le dan profundidad.
///
/// Incluye su propio [SafeArea] superior para que el degradado se extienda
/// hasta debajo de la barra de estado (cuyos iconos pasan a blanco).
class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;
  final double bottomRadius;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 10, 22, 24),
    this.gradient = AppColors.primaryGradient,
    this.bottomRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            children: [
              const Positioned(right: -70, top: -90, child: _Bubble(size: 220)),
              const Positioned(left: -40, bottom: -110, child: _Bubble(size: 180)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.06)],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  const _Bubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

/// Botón cuadrado translúcido para usar sobre [GradientHeader] u otras
/// superficies oscuras (campana de notificaciones, flash, cerrar…).
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const GlassIconButton({super.key, required this.icon, this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

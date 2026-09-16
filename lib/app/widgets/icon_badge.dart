import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Icono dentro de un cuadrado redondeado de color suave. Se usa como
/// "avatar" de listas, cabeceras de tarjetas y opciones.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double? iconSize;
  final double? radius;

  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primaryDark,
    this.background = AppColors.primarySoft,
    this.size = 44,
    this.iconSize,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius ?? size * 0.32)),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.5),
    );
  }
}

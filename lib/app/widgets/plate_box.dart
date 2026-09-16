import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Placa vehicular dibujada como una matrícula: marco oscuro, fondo
/// claro y tipografía monoespaciada.
class PlateBox extends StatelessWidget {
  final String placa;
  final double size;
  final bool onDark;

  const PlateBox({super.key, required this.placa, this.size = 22, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.textPrimary;
    final bg = onDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFFBFCFD);
    final border = onDark ? Colors.white.withValues(alpha: 0.45) : AppColors.textPrimary.withValues(alpha: 0.85);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.55, vertical: size * 0.3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.45),
        border: Border.all(color: border, width: 2),
      ),
      child: Text(placa, style: AppTextStyles.plate(size: size, color: fg), maxLines: 1),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'app_card.dart';

/// Tarjeta compacta de indicador: etiqueta pequeña, valor grande y un
/// icono de acento arriba a la derecha.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const StatTile({super.key, required this.label, required this.value, required this.icon, this.accent = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Icon(icon, size: 16, color: accent),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 24, color: accent == AppColors.primary ? AppColors.textPrimary : accent)),
          ),
        ],
      ),
    );
  }
}

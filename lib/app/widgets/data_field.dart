import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Par etiqueta/valor apilado ("Celda · A-12") usado dentro de tarjetas.
class DataField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final IconData? icon;

  const DataField({super.key, required this.label, required this.value, this.valueColor, this.mono = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final valueStyle = mono
        ? AppTextStyles.mono(size: 14, color: valueColor ?? AppColors.textPrimary)
        : AppTextStyles.bodyBold.copyWith(fontSize: 14, color: valueColor ?? AppColors.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.small.copyWith(letterSpacing: 0.6, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: valueColor ?? AppColors.textMuted),
              const SizedBox(width: 5),
            ],
            Expanded(child: Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ],
    );
  }
}

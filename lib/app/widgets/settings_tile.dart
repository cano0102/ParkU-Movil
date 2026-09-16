import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'icon_badge.dart';

/// Fila de ajustes dentro de una tarjeta: icono, título, subtítulo y, a
/// la derecha, un interruptor o un chevron (si tiene [onTap]).
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onChanged,
    this.onTap,
    this.iconColor,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final isSwitch = value != null;
    return InkWell(
      onTap: onTap ?? (isSwitch ? () => onChanged?.call(!value!) : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              size: 38,
              iconSize: 20,
              color: iconColor ?? AppColors.textSecondary,
              background: iconBackground ?? AppColors.neutralSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSwitch)
              Transform.scale(
                scale: 0.85,
                child: Switch(value: value!, onChanged: onChanged),
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textPlaceholder),
          ],
        ),
      ),
    );
  }
}

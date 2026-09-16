import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'icon_badge.dart';

/// Botón grande de acción rápida del inicio ("Escanear placa", "Registrar
/// salida", "Ver mapa"). En su variante [filled] usa el degradado
/// institucional con una sombra de color; en la otra, tarjeta blanca.
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool filled;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        gradient: filled ? AppColors.primaryGradient : null,
        color: filled ? null : Colors.white,
        borderRadius: borderRadius,
        border: filled ? null : Border.all(color: AppColors.border),
        boxShadow: filled ? AppColors.primaryShadow : AppColors.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                IconBadge(
                  icon: icon,
                  size: 40,
                  iconSize: 22,
                  color: filled ? Colors.white : AppColors.primaryDark,
                  background: filled ? Colors.white.withValues(alpha: 0.18) : AppColors.primarySoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: filled ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: filled ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/access_record.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'app_card.dart';
import 'icon_badge.dart';
import 'status_chip.dart';

/// Fila de un movimiento (ingreso, salida o novedad) del historial.
class MovementTile extends StatelessWidget {
  final AccessRecord record;
  final bool showStatus;

  const MovementTile({super.key, required this.record, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final hora = TimeOfDay.fromDateTime(record.hora).format(context);
    final IconData icon;
    final Color iconBg;
    final Color iconColor;
    final ChipTone tone;
    switch (record.estado) {
      case AccessStatus.dentro:
        icon = Icons.login_rounded;
        iconBg = AppColors.primarySoft;
        iconColor = AppColors.primaryDark;
        tone = ChipTone.success;
      case AccessStatus.salio:
        icon = Icons.logout_rounded;
        iconBg = AppColors.neutralSoft;
        iconColor = AppColors.textSecondary;
        tone = ChipTone.neutral;
      case AccessStatus.novedad:
        icon = Icons.report_gmailerrorred_rounded;
        iconBg = AppColors.dangerSoft;
        iconColor = AppColors.dangerDarker;
        tone = ChipTone.danger;
    }

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon, size: 40, iconSize: 20, color: iconColor, background: iconBg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(record.placa, style: AppTextStyles.mono(size: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  record.detalle,
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(hora, style: AppTextStyles.mono(size: 12, color: AppColors.textSecondary)),
              if (showStatus) ...[
                const SizedBox(height: 5),
                StatusChip(label: record.estadoLabel, tone: tone),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

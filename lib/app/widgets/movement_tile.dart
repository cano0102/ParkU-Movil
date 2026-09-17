import 'package:flutter/material.dart';
import '../../core/models/access_record.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'app_card.dart';
import 'icon_badge.dart';
import 'status_chip.dart';

/// Fila de un movimiento del historial. Para una estadía muestra la celda
/// (con su parqueadero), la hora de ingreso, la de salida y cuánto tiempo
/// estuvo; para una novedad, su descripción.
class MovementTile extends StatelessWidget {
  final AccessRecord record;
  final bool showStatus;

  const MovementTile({super.key, required this.record, this.showStatus = false});

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  static String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// "14:54" si es el mismo día que [referencia]; "12 sep 14:00" si no, para
  /// que una estadía que cruza de día no parezca de unas horas.
  static String _horaRelativa(DateTime d, DateTime referencia) {
    final mismoDia = d.year == referencia.year && d.month == referencia.month && d.day == referencia.day;
    if (mismoDia) return _hhmm(d);
    return '${d.day} ${_meses[d.month - 1]} ${_hhmm(d)}';
  }

  static String _duracion(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
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

    final lineas = <Widget>[];
    if (record.esEstadia) {
      final ingreso = record.ingreso!;
      final salida = record.salida;
      final referencia = record.hora;

      final celda = record.celdaConParqueadero;
      final cabecera = [
        if (celda != null) 'Celda $celda' else 'Sin celda asignada',
        if (record.conductor != null && record.conductor!.isNotEmpty) record.conductor!,
      ].join(' · ');
      lineas.add(
        Text(
          cabecera,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );

      final permanencia = record.permanencia;
      final tiempos = salida == null
          ? 'Ingreso ${_horaRelativa(ingreso, referencia)} · dentro${permanencia != null ? ' hace ${_duracion(permanencia)}' : ''}'
          : 'Ingreso ${_horaRelativa(ingreso, referencia)} → Salida ${_hhmm(salida)}${permanencia != null ? ' · ${_duracion(permanencia)}' : ''}';
      lineas.add(
        Text(
          tiempos,
          style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    } else {
      lineas.add(
        Text(
          record.detalle,
          style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      );
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
                for (var i = 0; i < lineas.length; i++) ...[if (i > 0) const SizedBox(height: 1), lineas[i]],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_hhmm(record.hora), style: AppTextStyles.mono(size: 12, color: AppColors.textSecondary)),
              if (showStatus) ...[const SizedBox(height: 5), StatusChip(label: record.estadoLabel, tone: tone)],
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../incidents/presentation/pages/report_incident_page.dart';
import '../../../parking_map/presentation/pages/parking_map_page.dart';
import 'driver_reservations_page.dart';

/// Inicio del conductor: enfocado en reserva de celdas y estado del parqueadero.
class DriverHomePage extends StatefulWidget {
  final VoidCallback? onVerTodo;

  const DriverHomePage({super.key, this.onVerTodo});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _repo = ParkingRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _repo.cuposDisponibles;
    final total = _repo.cuposTotales;
    final ocupadoPct = total == 0 ? 0.0 : (total - disponibles) / total;
    final movimientos = _repo.historialDeConductor().take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _repo.conductorNombre,
                        style: AppTextStyles.heading3.copyWith(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _repo.sede,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GlassIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No tienes notificaciones nuevas')),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconBadge(
                            icon: Icons.event_available_rounded,
                            size: 48,
                            iconSize: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RESERVA TU CELDA',
                                  style: AppTextStyles.overline.copyWith(fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Asegura tu lugar antes de llegar',
                                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 14),
                      Text(
                        'Solicita una celda; queda pendiente hasta que un administrador o vigilante la acepte.',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DriverReservePage()),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Solicitar reserva'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.map_outlined,
                  label: 'Ver mapa del parqueadero',
                  subtitle: 'Consulta la ocupación por zona',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ParkingMapPage(soloLectura: true),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.report_gmailerrorred_rounded,
                  label: 'Reportar queja',
                  subtitle: 'Cuéntanos si algo no estuvo bien',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportIncidentPage(tipoInicial: TipoNovedadUi.queja)),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'OCUPACIÓN GENERAL',
                              style: AppTextStyles.overline,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: '$disponibles / $total libres',
                            tone: ChipTone.success,
                            showDot: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ocupadoPct),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 10,
                            backgroundColor: AppColors.divider,
                            color: ocupadoPct >= 0.85
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(ocupadoPct * 100).round()}% del parqueadero ocupado',
                        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'MIS ÚLTIMOS MOVIMIENTOS'),
                const SizedBox(height: 10),
                if (movimientos.isEmpty)
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Aún no tienes movimientos',
                    subtitle: 'Cuando ingreses o salgas del campus aparecerá aquí.',
                  )
                else
                  for (final r in movimientos) ...[
                    MovementTile(record: r),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
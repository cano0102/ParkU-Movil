import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
import '../../../parking_map/presentation/pages/parking_map_page.dart';
import 'driver_vehicles_page.dart';

/// Inicio del conductor: estado de su vehículo, acceso rápido al mapa
/// del parqueadero y sus últimos movimientos.
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

  IconData _iconoTipo(VehicleType tipo) {
    switch (tipo) {
      case VehicleType.carro:
        return Icons.directions_car_rounded;
      case VehicleType.moto:
        return Icons.two_wheeler_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = _repo.misVehiculos();
    final vehiculoPrincipal = vehiculos.isNotEmpty ? vehiculos.first : null;
    final celda = vehiculoPrincipal != null ? _repo.celdaDePlaca(vehiculoPrincipal.placa) : null;
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
                      Text('Hola,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
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
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
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
                if (vehiculoPrincipal == null)
                  _SinVehiculoCard(
                    onRegistrar: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverVehiclesPage())),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(icon: _iconoTipo(vehiculoPrincipal.tipo), size: 48, iconSize: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MI VEHÍCULO', style: AppTextStyles.overline.copyWith(fontSize: 10)),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: PlateBox(placa: ParkingRepository.formatea(vehiculoPrincipal.placa), size: 18),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: celda != null ? 'Dentro' : 'Fuera',
                              tone: celda != null ? ChipTone.success : ChipTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 14),
                        if (celda != null)
                          Row(
                            children: [
                              Expanded(child: DataField(label: 'Celda asignada', value: celda.codigo, mono: true, icon: Icons.local_parking_rounded)),
                              Expanded(
                                child: DataField(
                                  label: 'Tiempo dentro',
                                  value: celda.permanencia != null ? ParkingRepository.formatDuration(celda.permanencia!) : '--',
                                  icon: Icons.schedule_rounded,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textPlaceholder),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tu vehículo no está registrado como dentro del campus en este momento.',
                                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ActionButton(
                  icon: Icons.map_outlined,
                  label: 'Ver mapa del parqueadero',
                  subtitle: 'Consulta la ocupación por zona',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParkingMapPage(soloLectura: true))),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('OCUPACIÓN GENERAL', style: AppTextStyles.overline, overflow: TextOverflow.ellipsis, maxLines: 1)),
                          const SizedBox(width: 8),
                          StatusChip(label: '$disponibles / $total libres', tone: ChipTone.success, showDot: false),
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
                            color: ocupadoPct >= 0.85 ? AppColors.warning : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${(ocupadoPct * 100).round()}% del parqueadero ocupado', style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(title: 'MIS ÚLTIMOS MOVIMIENTOS', actionLabel: 'Ver todo', onAction: widget.onVerTodo),
                const SizedBox(height: 10),
                if (movimientos.isEmpty)
                  const EmptyState(icon: Icons.inbox_outlined, title: 'Aún no tienes movimientos', subtitle: 'Cuando ingreses o salgas del campus aparecerá aquí.')
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

class _SinVehiculoCard extends StatelessWidget {
  final VoidCallback onRegistrar;
  const _SinVehiculoCard({required this.onRegistrar});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primarySoftBorder,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(icon: Icons.directions_car_outlined, size: 44, background: Colors.white),
          const SizedBox(height: 12),
          Text('Aún no tienes vehículos registrados', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryDeep, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Registra tu vehículo para agilizar tu ingreso en portería.',
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w500, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onRegistrar, child: const Text('Registrar vehículo')),
          ),
        ],
      ),
    );
  }
}

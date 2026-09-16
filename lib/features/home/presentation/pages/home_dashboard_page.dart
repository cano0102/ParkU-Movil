import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/parking_zone.dart';
import '../../../../core/models/vehicle.dart';
import '../../../exit/presentation/pages/exit_register_page.dart';
import '../../../parking_map/presentation/pages/parking_map_page.dart';
import '../../../scan/presentation/pages/scan_plate_page.dart';

class HomeDashboardPage extends StatefulWidget {
  final VoidCallback? onVerTodo;

  const HomeDashboardPage({super.key, this.onVerTodo});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
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

  IconData _iconForTipo(VehicleType tipo) {
    switch (tipo) {
      case VehicleType.carro:
        return Icons.directions_car_rounded;
      case VehicleType.moto:
        return Icons.two_wheeler_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _repo.cuposDisponibles;
    final total = _repo.cuposTotales;
    final ocupadoPct = total == 0 ? 0.0 : (total - disponibles) / total;
    final ultimos = _repo.historial.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(7),
                      child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buen turno,', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Text(
                            _repo.guardaNombre,
                            style: AppTextStyles.heading3.copyWith(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Portería ${_repo.porteria} · ${_repo.turno}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CUPOS DISPONIBLES', style: AppTextStyles.overline),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text('$disponibles', style: AppTextStyles.heading1.copyWith(fontSize: 46, height: 1)),
                                      const SizedBox(width: 6),
                                      Text('/ $total', style: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _OccupancyRing(value: ocupadoPct),
                        ],
                      ),
                      const SizedBox(height: 18),
                      for (int i = 0; i < _repo.zonas.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _ZonaRow(zona: _repo.zonas[i], icon: _iconForTipo(_repo.zonas[i].tipo)),
                      ],
                      if (_repo.zonas.isEmpty)
                        Text(
                          _repo.cargando ? 'Cargando ocupación…' : 'Sin información de celdas por ahora.',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParkingMapPage())),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined, size: 18, color: AppColors.primaryDark),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Ver mapa del parqueadero',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primaryDark),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        icon: Icons.photo_camera_rounded,
                        label: 'Escanear\nplaca',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanPlatePage())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        icon: Icons.logout_rounded,
                        label: 'Registrar\nsalida',
                        filled: false,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExitRegisterPage())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SectionHeader(title: 'ÚLTIMOS MOVIMIENTOS', actionLabel: 'Ver todo', onAction: widget.onVerTodo),
                const SizedBox(height: 10),
                if (ultimos.isEmpty)
                  const EmptyState(icon: Icons.inbox_outlined, title: 'Sin movimientos todavía', subtitle: 'Aquí verás los últimos ingresos y salidas registrados en portería.')
                else
                  for (final r in ultimos) ...[
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

/// Punto verde con un halo que "respira", para indicar turno activo.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + 8 * t,
                height: 6 + 8 * t,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryAccent.withValues(alpha: (1 - t) * 0.6)),
              ),
              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryAccent)),
            ],
          );
        },
      ),
    );
  }
}

/// Anillo de ocupación con el porcentaje en el centro.
class _OccupancyRing extends StatelessWidget {
  final double value;
  const _OccupancyRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    final color = value >= 0.85 ? AppColors.warning : AppColors.primary;
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.divider,
              color: color,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$pct%', style: AppTextStyles.bodyBold.copyWith(fontSize: 15, height: 1)),
                const SizedBox(height: 2),
                Text('ocupado', style: AppTextStyles.small.copyWith(fontSize: 9, letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZonaRow extends StatelessWidget {
  final ParkingZone zona;
  final IconData icon;
  const _ZonaRow({required this.zona, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isAlmostFull = zona.capacidad > 0 && zona.disponibles <= (zona.capacidad * 0.15).ceil();
    final pct = zona.capacidad == 0 ? 0.0 : zona.ocupados / zona.capacidad;
    final color = isAlmostFull ? AppColors.warning : AppColors.primary;
    return Row(
      children: [
        IconBadge(
          icon: icon,
          size: 38,
          iconSize: 20,
          color: isAlmostFull ? AppColors.warningDark : AppColors.primaryDark,
          background: isAlmostFull ? AppColors.warningSoft : AppColors.primarySoft,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${zona.tipo.zona} · ${zona.etiqueta}', style: AppTextStyles.bodyBold.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  const SizedBox(width: 8),
                  Text('${zona.ocupados}/${zona.capacidad}', style: AppTextStyles.mono(size: 13)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppColors.divider, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

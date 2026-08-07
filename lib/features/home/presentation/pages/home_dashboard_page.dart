import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart';
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
        return Icons.directions_car;
      case VehicleType.moto:
        return Icons.two_wheeler;
      case VehicleType.camion:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _repo.cuposDisponibles;
    final total = _repo.cuposTotales;
    final ocupadoPct = total == 0 ? 0.0 : (total - disponibles) / total;
    final ultimos = _repo.historial.take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Buen turno,', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_repo.guardaNombre, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                      _RoundIconButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No tienes notificaciones nuevas')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(7),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB3E6A1), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('Turno activo · Portería ${_repo.porteria} · ${_repo.turno}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CUPOS DISPONIBLES', style: AppTextStyles.overline),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text('$disponibles', style: AppTextStyles.heading1.copyWith(fontSize: 44)),
                                      const SizedBox(width: 6),
                                      Text('/ $total', style: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                border: Border.all(color: AppColors.primarySoftBorder),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${(ocupadoPct * 100).round()}% ocupado', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ocupadoPct,
                            minHeight: 10,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (int i = 0; i < _repo.zonas.length; i++) ...[
                          if (i > 0) ...[const SizedBox(height: 12), const Divider(height: 1, color: AppColors.divider), const SizedBox(height: 12)],
                          _ZonaRow(zona: _repo.zonas[i], icon: _iconForTipo(_repo.zonas[i].tipo)),
                        ],
                        const SizedBox(height: 14),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParkingMapPage())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.map_outlined, size: 16, color: AppColors.primaryDark),
                                const SizedBox(width: 6),
                                Text('Ver mapa del parqueadero', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
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
                        child: _ActionButton(
                          icon: Icons.photo_camera,
                          label: 'Escanear\nplaca',
                          filled: true,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanPlatePage())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.logout,
                          label: 'Registrar\nsalida',
                          filled: false,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExitRegisterPage())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ÚLTIMOS MOVIMIENTOS', style: AppTextStyles.overline),
                      GestureDetector(
                        onTap: widget.onVerTodo,
                        child: Text('Ver todo', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final r in ultimos) ...[
                    _MovementTile(record: r),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Colors.white, size: 22),
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
    final isAlmostFull = zona.disponibles <= (zona.capacidad * 0.15).ceil();
    return Row(
      children: [
        Icon(icon, size: 20, color: isAlmostFull ? AppColors.warning : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text('${zona.tipo.zona} · ${zona.etiqueta}', style: AppTextStyles.bodyBold)),
        Text('${zona.ocupados}/${zona.capacidad}', style: AppTextStyles.mono(size: 14)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26, color: filled ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.15, color: filled ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final AccessRecord record;
  const _MovementTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final esIngreso = record.estado == AccessStatus.dentro;
    final iconBg = esIngreso ? AppColors.primarySoft : AppColors.neutralSoft;
    final iconColor = esIngreso ? AppColors.primaryDark : AppColors.textSecondary;
    final icon = esIngreso ? Icons.login : Icons.logout;
    final hora = TimeOfDay.fromDateTime(record.hora).format(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.placa, style: AppTextStyles.mono(size: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(record.detalle, style: AppTextStyles.small.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(hora, style: AppTextStyles.mono(size: 12, color: AppColors.textPlaceholder)),
        ],
      ),
    );
  }
}

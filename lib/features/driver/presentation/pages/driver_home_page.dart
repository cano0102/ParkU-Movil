import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart';
import '../../../../core/models/vehicle.dart';
import '../../../parking_map/presentation/pages/parking_map_page.dart';
import 'driver_pass_page.dart';
import 'driver_vehicles_page.dart';

/// Inicio del conductor: estado de su vehículo, acceso rápido al pase
/// digital y al mapa del parqueadero, y sus últimos movimientos.
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
        return Icons.directions_car;
      case VehicleType.moto:
        return Icons.two_wheeler;
      case VehicleType.camion:
        return Icons.local_shipping;
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola,', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          _repo.conductorNombre,
                          style: AppTextStyles.heading3.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No tienes notificaciones nuevas')),
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                children: [
                  if (vehiculoPrincipal == null)
                    _SinVehiculoCard(
                      onRegistrar: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverVehiclesPage())),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                                child: Icon(_iconoTipo(vehiculoPrincipal.tipo), color: AppColors.primaryDark, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(ParkingRepository.formatea(vehiculoPrincipal.placa), style: AppTextStyles.plate(size: 26)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: celda != null ? AppColors.primarySoft : AppColors.neutralSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  celda != null ? 'Dentro' : 'Fuera',
                                  style: AppTextStyles.caption.copyWith(color: celda != null ? AppColors.primaryDark : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 16),
                          if (celda != null)
                            Row(
                              children: [
                                Expanded(child: _dato('Celda asignada', celda.codigo)),
                                Expanded(child: _dato('Tiempo dentro', celda.permanencia != null ? ParkingRepository.formatDuration(celda.permanencia!) : '--')),
                              ],
                            )
                          else
                            Text(
                              'Tu vehículo no está registrado como dentro del campus en este momento.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.qr_code_2,
                          label: 'Mostrar\ncódigo',
                          filled: true,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverPassPage())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.map_outlined,
                          label: 'Ver mapa\ndel parqueo',
                          filled: false,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParkingMapPage())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('OCUPACIÓN GENERAL', style: AppTextStyles.overline, overflow: TextOverflow.ellipsis, maxLines: 1)),
                            const SizedBox(width: 8),
                            Text('$disponibles / $total libres', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ocupadoPct,
                            minHeight: 8,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('MIS ÚLTIMOS MOVIMIENTOS', style: AppTextStyles.overline, overflow: TextOverflow.ellipsis, maxLines: 1)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onVerTodo,
                        child: Text('Ver todo', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (movimientos.isEmpty)
                    Text('Aún no tienes movimientos registrados.', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500))
                  else
                    for (final r in movimientos) ...[
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

  Widget _dato(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
      ],
    );
  }
}

class _SinVehiculoCard extends StatelessWidget {
  final VoidCallback onRegistrar;
  const _SinVehiculoCard({required this.onRegistrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primarySoftBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_car_outlined, color: AppColors.primaryDark, size: 28),
          const SizedBox(height: 10),
          Text('Aún no tienes vehículos registrados', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryDark, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Registra tu vehículo para generar tu pase digital y agilizar tu ingreso en portería.',
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRegistrar,
              child: const Text('Registrar vehículo'),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: filled ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, height: 1.15, color: filled ? Colors.white : AppColors.textPrimary),
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
                Text(record.detalle, style: AppTextStyles.small.copyWith(color: AppColors.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(hora, style: AppTextStyles.mono(size: 12, color: AppColors.textPlaceholder)),
        ],
      ),
    );
  }
}

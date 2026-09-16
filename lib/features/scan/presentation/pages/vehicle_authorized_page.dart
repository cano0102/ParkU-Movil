import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
import '../../../parking_map/presentation/pages/parking_map_page.dart';

class VehicleAuthorizedPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleAuthorizedPage({super.key, required this.vehicle});

  @override
  State<VehicleAuthorizedPage> createState() => _VehicleAuthorizedPageState();
}

class _VehicleAuthorizedPageState extends State<VehicleAuthorizedPage> {
  void _elegirCeldaYRegistrar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ParkingMapPage(vehicleParaAsignar: widget.vehicle)),
    );
  }

  void _reportarNovedad() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar novedad'),
        content: const Text('Se notificará a coordinación de vigilancia sobre este vehículo antes de autorizar el ingreso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ResultHeader(
            icon: Icons.verified_user_rounded,
            title: 'Acceso autorizado',
            subtitle: 'Vehículo registrado y vigente',
            placa: ParkingRepository.formatea(v.placa),
            chipLabel: v.tipo.label,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                        child: Text(v.iniciales, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.conductorNombre, style: AppTextStyles.bodyBold.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                StatusChip(label: v.conductorRol, tone: ChipTone.info, showDot: false),
                                const SizedBox(width: 8),
                                Flexible(child: Text(v.conductorDocumento, style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const IconBadge(icon: Icons.call_rounded, size: 40, iconSize: 20, background: AppColors.neutralSoft, color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATOS DEL VEHÍCULO', style: AppTextStyles.overline),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: DataField(label: 'Marca y línea', value: v.marcaLinea)),
                          const SizedBox(width: 12),
                          Expanded(child: DataField(label: 'Color', value: v.color)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DataField(
                              label: 'SOAT',
                              value: v.soatVigente ? 'Vigente' : 'Vencido',
                              valueColor: v.soatVigente ? AppColors.success : AppColors.danger,
                              icon: v.soatVigente ? Icons.verified_rounded : Icons.error_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: DataField(label: 'Tipo', value: v.tipo.label)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  color: AppColors.primarySoft,
                  borderColor: AppColors.primarySoftBorder,
                  onTap: _elegirCeldaYRegistrar,
                  child: Row(
                    children: [
                      const IconBadge(icon: Icons.local_parking_rounded, size: 46, iconSize: 24, background: Colors.white),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CELDA', style: AppTextStyles.overline.copyWith(color: AppColors.primaryDark)),
                            const SizedBox(height: 2),
                            Text('Se elige en el mapa del parqueadero', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryDeep, fontSize: 14)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _elegirCeldaYRegistrar,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_parking_rounded, size: 22),
                        SizedBox(width: 10),
                        Flexible(child: Text('Elegir celda', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: _reportarNovedad,
                  child: const Text('Reportar novedad'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

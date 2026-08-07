import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Acceso autorizado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                            SizedBox(height: 2),
                            Text('Vehículo registrado y vigente', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(ParkingRepository.formatea(v.placa), style: AppTextStyles.plate(size: 30, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                          child: Text(v.tipo.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
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
                              Text(v.conductorNombre, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(v.conductorRol, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                              Text(v.conductorDocumento, style: AppTextStyles.small),
                            ],
                          ),
                        ),
                        const Icon(Icons.call, color: AppColors.textPlaceholder),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DATOS DEL VEHÍCULO', style: AppTextStyles.overline),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _dato('Marca y línea', v.marcaLinea)),
                            Expanded(child: _dato('Color', v.color)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _dato('SOAT', v.soatVigente ? 'Vigente' : 'Vencido', color: v.soatVigente ? AppColors.success : AppColors.danger)),
                            Expanded(child: _dato('Último ingreso', 'Ayer, 7:12')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _elegirCeldaYRegistrar,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primarySoftBorder)),
                      child: Row(
                        children: [
                          const Icon(Icons.local_parking, color: AppColors.primaryDark, size: 26),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CELDA', style: AppTextStyles.overline.copyWith(color: AppColors.primaryDark)),
                                Text('Se elige en el mapa del parqueadero', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryDark, fontSize: 15)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.primaryDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _elegirCeldaYRegistrar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_parking, size: 22),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text('Elegir celda', overflow: TextOverflow.ellipsis, maxLines: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _reportarNovedad,
                    child: Text('Reportar novedad', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 14, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

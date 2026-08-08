import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';

/// Pase digital del conductor: un código QR con su placa para que el
/// guarda de portería lo escanee en vez de digitar la placa a mano.
class DriverPassPage extends StatelessWidget {
  const DriverPassPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ParkingRepository.instance;
    final vehiculos = repo.misVehiculos();
    final vehiculo = vehiculos.isEmpty ? null : vehiculos.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Mi pase digital', style: AppTextStyles.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: vehiculo == null
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'Registra un vehículo para generar tu pase digital.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 12))],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                _iniciales(repo.conductorNombre),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(repo.conductorNombre, style: AppTextStyles.heading3.copyWith(fontSize: 18), textAlign: TextAlign.center),
                            const SizedBox(height: 2),
                            Text(vehiculo.conductorRol, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 20),
                            const Divider(height: 1, color: AppColors.divider),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: QrImageView(
                                data: 'PARKU:${vehiculo.placa}',
                                version: QrVersions.auto,
                                size: 200,
                                gapless: true,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
                                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(ParkingRepository.formatea(vehiculo.placa), style: AppTextStyles.plate(size: 30)),
                            const SizedBox(height: 6),
                            Text('${vehiculo.marcaLinea} · ${vehiculo.color}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: vehiculo.soatVigente ? AppColors.primarySoft : AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                vehiculo.soatVigente ? 'SOAT vigente' : 'SOAT vencido',
                                style: AppTextStyles.caption.copyWith(color: vehiculo.soatVigente ? AppColors.primaryDark : AppColors.dangerDarker),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Preséntalo al guarda de portería para agilizar tu ingreso.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) return (partes[0][0] + partes[1][0]).toUpperCase();
    return partes.isNotEmpty ? partes[0].substring(0, 1).toUpperCase() : '?';
  }
}

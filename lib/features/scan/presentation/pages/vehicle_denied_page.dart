import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../home/presentation/pages/home_shell.dart';

class VehicleDeniedPage extends StatelessWidget {
  final String placa;

  const VehicleDeniedPage({super.key, required this.placa});

  void _registrarVisitante(BuildContext context) {
    ParkingRepository.instance.registrarVisitante(placa);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehículo registrado como visitante en Zona D')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  void _reportarIncidente(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar incidente'),
        content: const Text('Se generará un reporte para el equipo de vigilancia con la placa y la hora del intento de ingreso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _denegarIngreso(BuildContext context) {
    ParkingRepository.instance.registrarDenegado(placa);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingreso denegado y registrado en el historial')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final placaFormateada = ParkingRepository.formatea(placa);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
              color: AppColors.danger,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gpp_maybe, color: Colors.white, size: 40),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehículo no autorizado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                            SizedBox(height: 2),
                            Text('Sin registro en el sistema', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(placaFormateada, style: AppTextStyles.plate(size: 30, color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(999)),
                          child: const Text('Sin ficha', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
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
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.dangerSoftBorder)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MOTIVO', style: AppTextStyles.overline.copyWith(color: AppColors.dangerDarker)),
                        const SizedBox(height: 10),
                        Text(
                          'La placa no coincide con ningún vehículo registrado en el Complejo Central. No hay reserva activa a esta hora.',
                          style: TextStyle(color: AppColors.dangerDark, fontSize: 14, height: 1.6),
                        ),
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
                        Text('CUPOS PARA VISITANTES', style: AppTextStyles.overline),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('7', style: AppTextStyles.heading1.copyWith(fontSize: 32)),
                            const SizedBox(width: 6),
                            Text('disponibles en Zona D', style: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OptionTile(
                    icon: Icons.person_add,
                    iconColor: AppColors.primary,
                    label: 'Registrar como visitante',
                    onTap: () => _registrarVisitante(context),
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    icon: Icons.report,
                    iconColor: AppColors.warning,
                    label: 'Reportar incidente',
                    onTap: () => _reportarIncidente(context),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => _denegarIngreso(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block, size: 22),
                          SizedBox(width: 10),
                          Text('Denegar ingreso'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Volver a escanear', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 15))),
            const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
          ],
        ),
      ),
    );
  }
}

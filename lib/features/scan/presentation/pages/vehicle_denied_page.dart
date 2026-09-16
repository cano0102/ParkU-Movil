import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/network/api_exception.dart';
import '../../../home/presentation/pages/home_shell.dart';
import '../../../incidents/presentation/pages/report_incident_page.dart';

class VehicleDeniedPage extends StatelessWidget {
  final String placa;

  const VehicleDeniedPage({super.key, required this.placa});

  Future<void> _registrarVisitante(BuildContext context) async {
    try {
      await ParkingRepository.instance.registrarVisitante(placa);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo registrado como visitante')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _reportarIncidente(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportIncidentPage(
          tipoInicial: TipoNovedadUi.otro,
          placaContexto: ParkingRepository.formatea(placa),
        ),
      ),
    );
  }

  Future<void> _denegarIngreso(BuildContext context) async {
    try {
      await ParkingRepository.instance.registrarDenegado(placa);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingreso denegado y registrado en el historial')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final placaFormateada = ParkingRepository.formatea(placa);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ResultHeader(
            icon: Icons.gpp_maybe_rounded,
            title: 'Vehículo no autorizado',
            subtitle: 'Sin registro en el sistema',
            placa: placaFormateada,
            chipLabel: 'Sin ficha',
            gradient: AppColors.dangerGradient,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              children: [
                AppCard(
                  color: AppColors.dangerSoft,
                  borderColor: AppColors.dangerSoftBorder,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(icon: Icons.info_outline_rounded, size: 40, iconSize: 21, background: Colors.white, color: AppColors.dangerDarker),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MOTIVO', style: AppTextStyles.overline.copyWith(color: AppColors.dangerDarker)),
                            const SizedBox(height: 6),
                            const Text(
                              'La placa no coincide con ningún vehículo registrado en el sistema. No hay reserva activa a esta hora.',
                              style: TextStyle(color: AppColors.dangerDark, fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '¿QUÉ DESEAS HACER?'),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.person_add_alt_1_rounded,
                  iconColor: AppColors.primaryDark,
                  iconBackground: AppColors.primarySoft,
                  label: 'Registrar como visitante',
                  subtitle: 'Permite el ingreso puntual y deja constancia',
                  onTap: () => _registrarVisitante(context),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.report_rounded,
                  iconColor: AppColors.warningDark,
                  iconBackground: AppColors.warningSoft,
                  label: 'Reportar incidente',
                  subtitle: 'Notifica al equipo de vigilancia',
                  onTap: () => _reportarIncidente(context),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => _denegarIngreso(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block_rounded, size: 22),
                        SizedBox(width: 10),
                        Flexible(child: Text('Denegar ingreso', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver a escanear'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, size: 44, iconSize: 22, color: iconColor, background: iconBackground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textPlaceholder),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  const _Feature({required this.icon, required this.title, required this.description});
}

const _features = [
  _Feature(
    icon: Icons.photo_camera,
    title: 'Lectura automática de placas',
    description: 'Escanea la placa con la cámara y verifica el vehículo al instante.',
  ),
  _Feature(
    icon: Icons.local_parking,
    title: 'Ocupación en tiempo real',
    description: 'Consulta los cupos disponibles por zona en cada turno.',
  ),
  _Feature(
    icon: Icons.history,
    title: 'Historial y trazabilidad',
    description: 'Revisa ingresos, salidas y novedades de la portería.',
  ),
];

/// Presentación del módulo de portería en la pantalla de bienvenida:
/// una frase corta y las tres capacidades principales de la app.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control de acceso vehicular',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 6),
          Text(
            'Todo el flujo de portería y vigilancia, desde el celular del guarda.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          for (final feature in _features) ...[
            _FeatureTile(feature: feature),
            if (feature != _features.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(feature.icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  feature.description,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import 'header_clipper.dart';

/// Encabezado de bienvenida: ola verde institucional con el logo y el
/// nombre de la app, en la misma línea visual que el resto de ParkU.
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        height: 320,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 22),
              Text('ParkU', style: AppTextStyles.heading1.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

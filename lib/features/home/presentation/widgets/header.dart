import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import 'header_clipper.dart';

/// Encabezado de bienvenida: ola verde institucional con el logo y el
/// nombre de la app, en la misma línea visual que el resto de ParkU.
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipPath(
        clipper: HeaderClipper(),
        child: Container(
          height: 330,
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(right: -60, top: -70, child: _circle(220)),
              Positioned(left: -50, bottom: 10, child: _circle(160)),
              Positioned(right: 40, bottom: 60, child: _circle(70)),
              SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
                      ),
                      child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),
                    Text('ParkU', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 36)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'PORTERÍA · SENA',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

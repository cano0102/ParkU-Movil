import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../widgets/header.dart';
import '../widgets/hero_section.dart';

/// Bienvenida para quien no tiene sesión: presentación del módulo y
/// acceso al inicio de sesión. La verificación de sesión guardada ocurre
/// antes, en la introducción (SplashPage).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Header(),
                  const SizedBox(height: 22),
                  const HeroSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          BottomActionBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ingresar'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('SENA · Servicio Nacional de Aprendizaje', style: AppTextStyles.small, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../widgets/header.dart';
import '../widgets/hero_section.dart';

/// Bienvenida para quien no tiene sesión: presentación del módulo y
/// acceso al inicio de sesión. La verificación de sesión guardada ocurre
/// antes, en la introducción (SplashPage).
///
/// Las cuentas se crean en la web de ParkU, no en la app: desde aquí solo
/// se abre el navegador en el registro.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  /// Registro en la web de ParkU (mismo backend que esta app).
  static final Uri registroWeb = Uri.parse('https://park-u.vercel.app/');

  static Future<void> abrirRegistroWeb(BuildContext context) async {
    final abierto = await launchUrl(registroWeb, mode: LaunchMode.externalApplication);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir el navegador. Entra a ${registroWeb.host} para registrarte.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [const Header(), const SizedBox(height: 22), const HeroSection(), const SizedBox(height: 16)]),
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
                      children: [Text('Ingresar'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 20)],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: () => abrirRegistroWeb(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Regístrate en park-u.vercel.app'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('SENA · Servicio Nacional de Aprendizaje', style: AppTextStyles.small, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

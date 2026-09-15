import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/data/session_repository.dart';
import '../widgets/header.dart';
import '../widgets/hero_section.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _verificandoSesion = true;

  @override
  void initState() {
    super.initState();
    _intentarSesionGuardada();
  }

  Future<void> _intentarSesionGuardada() async {
    await SessionRepository.instance.restaurar();
    if (!mounted) return;
    if (SessionRepository.instance.autenticado) {
      await ParkingRepository.instance.iniciar();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        SessionRepository.instance.esConductor ? AppRoutes.driverHome : AppRoutes.home,
        (route) => false,
      );
      return;
    }
    setState(() => _verificandoSesion = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoSesion) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Header(),
                    const SizedBox(height: 28),
                    const HeroSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
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
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SENA · Servicio Nacional de Aprendizaje',
                    style: AppTextStyles.small,
                    textAlign: TextAlign.center,
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

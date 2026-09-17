import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login.dart';
import '../features/auth/presentation/pages/register.dart'; // ← NUEVO
import '../features/driver/presentation/pages/driver_home_shell.dart';
import '../features/home/presentation/pages/home_shell.dart';
import '../features/home/presentation/pages/welcome_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

/// Nombres de las rutas de nivel superior de la app. Las pantallas del
/// flujo de escaneo (confirmar, autorizado, denegado, salida) se navegan
/// con Navigator.push directo porque llevan datos tipados (placa, vehículo).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register'; // ← se agregó el ';'
  static const String home = '/home';
  static const String driverHome = '/driver-home';
}

class AppRouter {
  AppRouter._();

  static Widget _pageFor(String? name) {
    switch (name) {
      case AppRoutes.splash:
        return const SplashPage();
      case AppRoutes.welcome:
        return const WelcomePage();
      case AppRoutes.login:
        return const LoginPage();
      case AppRoutes.register: // ← NUEVO
        return const RegisterPage();
      case AppRoutes.home:
        return const HomeShell();
      case AppRoutes.driverHome:
        return const DriverHomeShell();
      default:
        return Scaffold(body: Center(child: Text('Ruta no encontrada: $name')));
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(settings: settings, builder: (_) => _pageFor(settings.name));
  }

  /// Ruta con fundido, para salir de la introducción sin el deslizamiento
  /// de las transiciones normales.
  static Route<dynamic> fadeRoute(String name) {
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => _pageFor(name),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
      },
    );
  }
}
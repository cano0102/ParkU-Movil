import 'package:flutter/material.dart';
import '../features/auth/presentation/pages/login.dart';
import '../features/driver/presentation/pages/driver_home_shell.dart';
import '../features/home/presentation/pages/home_shell.dart';
import '../features/home/presentation/pages/welcome_page.dart';

/// Nombres de las rutas de nivel superior de la app. Las pantallas del
/// flujo de escaneo (confirmar, autorizado, denegado, salida) se navegan
/// con Navigator.push directo porque llevan datos tipados (placa, vehículo).
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String driverHome = '/driver-home';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeShell());
      case AppRoutes.driverHome:
        return MaterialPageRoute(builder: (_) => const DriverHomeShell());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}

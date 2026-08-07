import 'package:flutter/material.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Widget principal de la aplicación.
/// StatelessWidget se utiliza porque este widget no cambia su estado.
class ParkUApp extends StatelessWidget {
  const ParkUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Elimina la etiqueta "DEBUG" de la esquina superior derecha.
      debugShowCheckedModeBanner: false,

      // Título de la aplicación.
      title: 'ParkU',

      // Tema personalizado definido en app_theme.dart.
      theme: AppTheme.lightTheme,

      // Ruta inicial y generador de rutas con nombre de la app.
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

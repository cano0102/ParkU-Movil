import 'package:flutter/material.dart';
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

      // Pantalla inicial de la aplicación.
      home: const HomePage(),
    );
  }
}

/// Pantalla principal (temporal).
/// Más adelante podrás reemplazarla por LoginPage,
/// SplashPage o DashboardPage.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior.
      appBar: AppBar(
        title: const Text('ParkU'),
      ),

      // Contenido de la pantalla.
      body: const Center(
        child: Text(
          'Bienvenido a ParkU',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
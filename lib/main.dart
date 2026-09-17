import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parku_movil/app/app.dart';
import 'package:parku_movil/core/network/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La dirección de la API puede haberse cambiado desde la app (celular
  // físico): hay que leerla antes de la primera petición del splash.
  await ApiConfig.cargar();
  // Barra de estado transparente para que las cabeceras con degradado se
  // extiendan hasta el borde superior; cada pantalla define el color de
  // sus iconos (claros u oscuros) con AnnotatedRegion.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ParkUApp());
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parku_movil/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

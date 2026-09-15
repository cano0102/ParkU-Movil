import 'package:flutter/foundation.dart';

/// Dirección base de la API (Api-ParkU). Se puede sobrescribir al compilar o
/// depurar con `--dart-define=API_BASE_URL=http://192.168.1.10:3000/api`,
/// necesario para probar en un dispositivo físico (no en un emulador) contra
/// una API corriendo en el computador.
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // El emulador de Android no puede resolver "localhost" como el propio
    // computador: 10.0.2.2 es la dirección que Android reserva para eso.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }
}

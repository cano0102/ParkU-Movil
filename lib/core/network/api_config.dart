import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Dirección base de la API (Api-ParkU), resuelta en este orden:
///
/// 1. La que la persona guardó desde la app ("Configurar servidor" en la
///    pantalla de inicio de sesión). Se conserva entre arranques.
/// 2. `--dart-define=API_BASE_URL=http://192.168.1.10:3000/api` al compilar.
/// 3. La predeterminada según dónde corre la app: en el emulador de Android
///    `10.0.2.2` (así ve Android al propio computador); en escritorio, Chrome
///    o iOS, `localhost`.
/// 4. Si la predeterminada no responde, la API desplegada en la nube
///    ([nube]), que es la misma que usa el frontend web. Ese cambio dura
///    solo la sesión: al siguiente arranque se vuelve a intentar la local.
///
/// Un celular físico no puede usar `localhost` ni `10.0.2.2`: o se le fija
/// la IP del computador (opción 1 o 2) o cae solo en la nube (opción 4).
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const String _kBaseUrl = 'parku_api_base_url';

  /// Api-ParkU desplegada (Render). Misma base de datos que la local.
  static const String nube = 'https://api-parku-e017.onrender.com/api';

  static String? _personalizada;
  static String? _respaldo;

  static String get predeterminada {
    if (_override.isNotEmpty) return _override;
    // El emulador de Android no puede resolver "localhost" como el propio
    // computador: 10.0.2.2 es la dirección que Android reserva para eso.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String get baseUrl => _personalizada ?? _respaldo ?? predeterminada;

  /// true si la persona fijó una dirección distinta a la predeterminada.
  static bool get esPersonalizada => _personalizada != null;

  /// true si en esta sesión se cayó a la nube porque la local no respondió.
  static bool get usandoRespaldo => _personalizada == null && _respaldo != null;

  /// Texto corto para mostrar de dónde se están leyendo los datos.
  static String get descripcion {
    if (esPersonalizada) return _personalizada!;
    if (usandoRespaldo) return 'Nube (Render)';
    return 'Local · ${predeterminada.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/api$'), '')}';
  }

  /// Recupera la dirección guardada (si la hay). Se llama una vez al arrancar,
  /// antes de la primera petición.
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardada = prefs.getString(_kBaseUrl);
      _personalizada = (guardada == null || guardada.isEmpty) ? null : guardada;
    } catch (_) {
      _personalizada = null;
    }
  }

  /// Fija la dirección de la API. Con `null` o vacío vuelve a la
  /// predeterminada. Acepta lo que la persona escriba a medio camino
  /// (`192.168.1.10:3000`, `http://192.168.1.10:3000/`) y lo completa.
  static Future<String> guardar(String? url) async {
    final normalizada = (url == null || url.trim().isEmpty) ? null : normalizar(url);
    final prefs = await SharedPreferences.getInstance();
    _respaldo = null;
    if (normalizada == null || normalizada == predeterminada) {
      _personalizada = null;
      await prefs.remove(_kBaseUrl);
    } else {
      _personalizada = normalizada;
      await prefs.setString(_kBaseUrl, normalizada);
    }
    return baseUrl;
  }

  /// `192.168.1.10:3000` → `http://192.168.1.10:3000/api`.
  static String normalizar(String url) {
    var limpia = url.trim();
    if (!limpia.contains('://')) limpia = 'http://$limpia';
    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }
    if (!limpia.toLowerCase().endsWith('/api')) limpia = '$limpia/api';
    return limpia;
  }

  /// Golpea `GET /health` de la dirección dada y devuelve `null` si responde
  /// bien, o un mensaje con el motivo del fallo para mostrar en pantalla.
  static Future<String?> probar([String? url, Duration timeout = const Duration(seconds: 8)]) async {
    final base = url == null ? baseUrl : normalizar(url);
    try {
      final respuesta = await http.get(Uri.parse('$base/health')).timeout(timeout);
      if (respuesta.statusCode != 200) {
        return 'El servidor respondió con el código ${respuesta.statusCode}. ¿Es la dirección de Api-ParkU?';
      }
      try {
        final cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is Map && cuerpo['database'] != null && cuerpo['database'] != 'connected') {
          return 'La API responde pero no tiene conexión con su base de datos (revisa su .env).';
        }
      } catch (_) {
        // Un cuerpo no-JSON con 200 sigue siendo "algo escucha ahí".
      }
      return null;
    } catch (_) {
      return 'No hay respuesta en $base. Verifica que la API esté corriendo y que la dirección sea alcanzable desde este dispositivo.';
    }
  }

  /// Cuando la dirección predeterminada no contesta, prueba la de la nube y,
  /// si responde, la deja como base para el resto de la sesión. Devuelve
  /// `true` si cambió (y por tanto vale la pena reintentar la petición).
  ///
  /// No aplica si la persona fijó una dirección a mano: si escribió una IP
  /// es porque quiere esa, y un fallo ahí debe verse como tal.
  static Future<bool> intentarRespaldo() async {
    if (_personalizada != null || _respaldo != null) return false;
    // Render duerme el servicio cuando nadie lo usa y tarda en despertar: la
    // primera petición puede demorar bastante más que una API local.
    final error = await probar(nube, const Duration(seconds: 40));
    if (error != null) return false;
    _respaldo = nube;
    return true;
  }

  /// Olvida el respaldo para volver a intentar la dirección predeterminada
  /// (p. ej. después de que la persona levantó la API local).
  static void olvidarRespaldo() => _respaldo = null;
}

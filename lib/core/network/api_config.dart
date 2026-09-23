import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Dirección base de la API (Api-ParkU), resuelta en este orden:
///
/// 1. La que la persona guardó desde la app ("Configurar servidor" en la
///    pantalla de inicio de sesión). Se conserva entre arranques.
/// 2. `--dart-define=API_BASE_URL=...` al compilar.
/// 3. La API desplegada en la nube ([nube]).
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');
  static const String _kBaseUrl = 'parku_api_base_url';

  /// Api-ParkU desplegada (Render), usada por la versión de entrega.
  static const String nube = 'https://api-parku-e017.onrender.com/api';

  static String? _personalizada;
  static String? _respaldo;

  static String get predeterminada {
    if (_override.isNotEmpty) return _override;
    return nube;
  }

  static String get baseUrl => predeterminada;

  /// true si la persona fijó una dirección distinta a la predeterminada.
  static bool get esPersonalizada => false;

  /// true si en esta sesión se cayó a la nube porque la local no respondió.
  static bool get usandoRespaldo => false;

  /// Texto corto para mostrar de dónde se están leyendo los datos.
  static String get descripcion {
    if (esPersonalizada) return _personalizada!;
    if (usandoRespaldo) return 'Nube (Render)';
    return 'Nube (Render)';
  }

  /// Recupera la dirección guardada (si la hay). Se llama una vez al arrancar,
  /// antes de la primera petición.
  static Future<void> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kBaseUrl)) {
        await prefs.remove(_kBaseUrl);
      }
      _personalizada = null;
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
    return predeterminada;
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

  /// Conservado para que el cliente pueda reintentar la nube tras un fallo
  /// transitorio sin cambiar la URL pública configurada.
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

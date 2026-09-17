import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP hacia Api-ParkU: agrega la URL base, el token de sesión y
/// desempaqueta las respuestas (algunos endpoints devuelven
/// `{success, data}`, otros el recurso "crudo" directamente).
class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  final http.Client _http = http.Client();
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {'Content-Type': 'application/json', if (_token != null) 'Authorization': 'Bearer $_token'};

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? params;
    if (query != null && query.isNotEmpty) {
      params = {};
      for (final entrada in query.entries) {
        if (entrada.value == null) continue;
        params[entrada.key] = entrada.value.toString();
      }
    }
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: params);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _enviar(() => _http.get(_uri(path, query), headers: _headers));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _enviar(() => _http.post(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)));
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _enviar(() => _http.put(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)));
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _enviar(() => _http.patch(_uri(path), headers: _headers, body: body == null ? null : jsonEncode(body)));
  }

  Future<dynamic> delete(String path) {
    return _enviar(() => _http.delete(_uri(path), headers: _headers));
  }

  /// Una API local responde al instante o no responde (y en un celular
  /// físico apuntando a 10.0.2.2 la petición se queda colgada: por eso el
  /// tope). La de la nube (Render) puede tardar en despertar.
  static const _timeoutLocal = Duration(seconds: 15);
  static const _timeoutNube = Duration(seconds: 45);

  Duration get _timeout => ApiConfig.usandoRespaldo || ApiConfig.baseUrl.startsWith('https://') ? _timeoutNube : _timeoutLocal;

  Future<dynamic> _enviar(Future<http.Response> Function() hacer) async {
    http.Response respuesta;
    try {
      respuesta = await hacer().timeout(_timeout);
    } catch (_) {
      // La API predeterminada (local) no contestó: se prueba la de la nube y,
      // si está viva, se repite la petición contra ella. `hacer` vuelve a
      // construir la URI, así que toma la nueva base sola.
      if (await ApiConfig.intentarRespaldo()) {
        try {
          respuesta = await hacer().timeout(_timeoutNube);
        } catch (_) {
          throw ApiException(_mensajeSinConexion());
        }
      } else {
        throw ApiException(_mensajeSinConexion());
      }
    }

    final cuerpo = respuesta.body;
    dynamic decodificado;
    if (cuerpo.isNotEmpty) {
      try {
        decodificado = jsonDecode(cuerpo);
      } catch (_) {
        decodificado = null;
      }
    }

    if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
      if (decodificado is Map && decodificado.containsKey('data')) return decodificado['data'];
      return decodificado;
    }

    String? mensaje;
    if (decodificado is Map) {
      final errores = decodificado['errors'];
      if (errores is List && errores.isNotEmpty) {
        mensaje = errores.map((e) => e is Map ? e['message'] : e).join('\n');
      }
      mensaje ??= decodificado['message']?.toString();
    }
    throw ApiException(mensaje ?? 'Error del servidor (${respuesta.statusCode})', statusCode: respuesta.statusCode);
  }

  /// Sin código de estado la app ni siquiera llegó a hablar con la API. El
  /// mensaje dice a qué dirección intentó, que es lo primero que hay que
  /// revisar (emulador vs. celular físico, API apagada, IP cambiada...).
  static String _mensajeSinConexion() {
    return 'No se pudo conectar con el servidor en ${ApiConfig.baseUrl}. '
        'Verifica que Api-ParkU esté corriendo y, si usas un celular físico, '
        'configura la dirección del servidor en la pantalla de inicio de sesión.';
  }
}

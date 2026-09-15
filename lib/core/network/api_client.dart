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

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

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

  Future<dynamic> delete(String path) {
    return _enviar(() => _http.delete(_uri(path), headers: _headers));
  }

  Future<dynamic> _enviar(Future<http.Response> Function() hacer) async {
    http.Response respuesta;
    try {
      respuesta = await hacer().timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const ApiException('No se pudo conectar con el servidor. Verifica tu conexión o la dirección de la API.');
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
}

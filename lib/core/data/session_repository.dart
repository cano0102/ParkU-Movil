import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// Roles reales de Api-ParkU (src/config/roles.js). No están en el orden que
/// uno esperaría: Vigilante es 2, no 1.
class Roles {
  Roles._();
  static const int admin = 1;
  static const int vigilante = 2;
  static const int conductor = 3;
}

/// Sesión del usuario autenticado: token JWT, datos de la cuenta y (para un
/// conductor) el id de su registro de Conductor, que es el que usan el resto
/// de endpoints (vehículos, etc.), no el id de la cuenta.
class SessionRepository extends ChangeNotifier {
  SessionRepository._internal();

  static final SessionRepository instance = SessionRepository._internal();

  static const _kToken = 'parku_token';

  String? token;
  int? usuarioId;
  String? correo;
  String? nombre;
  int? rol;
  String? rolNombre;
  String? tipoDocumento;
  String? numeroDocumento;
  List<String> permisos = const [];

  /// Id del registro de Conductor vinculado a esta cuenta (solo si rol == conductor).
  int? conductorId;

  bool get autenticado => token != null;
  bool get esConductor => rol == Roles.conductor;
  bool get esVigilanteOAdmin => rol == Roles.vigilante || rol == Roles.admin;

  /// Intenta recuperar una sesión guardada al abrir la app. Si el token ya
  /// no es válido, la limpia y deja la app en el estado de "sin sesión".
  Future<void> restaurar() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenGuardado = prefs.getString(_kToken);
    if (tokenGuardado == null) return;

    token = tokenGuardado;
    ApiClient.instance.setToken(tokenGuardado);
    try {
      final data = await ApiClient.instance.get('/auth/verificar');
      _aplicarUsuario(data['usuario'] as Map<String, dynamic>);
      if (esConductor) await _resolverConductorId();
    } catch (_) {
      await cerrarSesion();
    }
  }

  Future<void> iniciarSesion({required String correo, required String contrasena}) async {
    final data = await ApiClient.instance.post('/auth/login', body: {
      'correo': correo,
      'contrasena': contrasena,
    });
    token = data['token'] as String;
    ApiClient.instance.setToken(token);
    _aplicarUsuario(data['user'] as Map<String, dynamic>);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token!);

    if (esConductor) await _resolverConductorId();
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    token = null;
    usuarioId = null;
    correo = null;
    nombre = null;
    rol = null;
    rolNombre = null;
    tipoDocumento = null;
    numeroDocumento = null;
    permisos = const [];
    conductorId = null;
    ApiClient.instance.setToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    notifyListeners();
  }

  void _aplicarUsuario(Map<String, dynamic> u) {
    usuarioId = u['id'] as int?;
    correo = u['correo'] as String?;
    nombre = u['nombre'] as String?;
    rol = u['rol'] as int?;
    rolNombre = u['rol_nombre'] as String?;
    tipoDocumento = u['tipo_documento'] as String?;
    numeroDocumento = u['numero_documento'] as String?;
    final listaPermisos = u['permisos'];
    permisos = listaPermisos is List ? listaPermisos.map((e) => e.toString()).toList() : const [];
  }

  /// GET /api/conductores/usuario/:usuarioId — el id de Conductor no viaja en
  /// el login porque una cuenta puede no tener uno vinculado.
  Future<void> _resolverConductorId() async {
    try {
      final data = await ApiClient.instance.get('/conductores/usuario/$usuarioId');
      conductorId = data is Map ? data['id'] as int? : null;
    } catch (_) {
      conductorId = null;
    }
  }
}

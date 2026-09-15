/// Error de red o de la API, con el mensaje ya listo para mostrar al usuario
/// (el que manda el backend en `message`, o uno genérico si no hay respuesta).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get esNoAutorizado => statusCode == 401;
  bool get esProhibido => statusCode == 403;

  @override
  String toString() => message;
}

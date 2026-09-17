/// Tipos de notificación de Api-ParkU (`tipo_notificacion_enum`).
enum TipoNotificacion { acceso, reserva, novedad, cambioEstado, alerta }

extension TipoNotificacionApi on TipoNotificacion {
  static TipoNotificacion desdeApi(String? valor) {
    switch ((valor ?? '').toUpperCase()) {
      case 'ACCESO':
        return TipoNotificacion.acceso;
      case 'RESERVA':
        return TipoNotificacion.reserva;
      case 'NOVEDAD':
        return TipoNotificacion.novedad;
      case 'CAMBIO_ESTADO':
        return TipoNotificacion.cambioEstado;
      default:
        return TipoNotificacion.alerta;
    }
  }
}

/// Una notificación del usuario con sesión (`GET /notificaciones`). Para el
/// conductor las crea la API al registrar el ingreso/salida de su vehículo y
/// al cambiar el estado de su reserva (avisosConductor.service.js); van
/// acompañadas del correo correspondiente.
class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final TipoNotificacion tipo;
  final DateTime fecha;
  bool leida;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    required this.leida,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as int,
      titulo: (json['titulo'] as String?) ?? '',
      mensaje: (json['mensaje'] as String?) ?? '',
      tipo: TipoNotificacionApi.desdeApi(json['tipo'] as String?),
      fecha: (DateTime.tryParse(json['fecha_hora']?.toString() ?? '') ?? DateTime.now()).toLocal(),
      leida: json['leida'] == true,
    );
  }
}

/// Estados reales de una reserva en Api-ParkU (reservaVehiculos.models.js).
enum EstadoReserva { pendiente, aceptada, rechazada, terminada, cancelada }

extension EstadoReservaApi on EstadoReserva {
  static EstadoReserva desdeApi(String? valor) {
    switch ((valor ?? '').toUpperCase()) {
      case 'ACEPTADA':
        return EstadoReserva.aceptada;
      case 'RECHAZADA':
        return EstadoReserva.rechazada;
      case 'TERMINADA':
        return EstadoReserva.terminada;
      case 'CANCELADA':
        return EstadoReserva.cancelada;
      default:
        return EstadoReserva.pendiente;
    }
  }

  String get label {
    switch (this) {
      case EstadoReserva.pendiente:
        return 'Pendiente';
      case EstadoReserva.aceptada:
        return 'Aceptada';
      case EstadoReserva.rechazada:
        return 'Rechazada';
      case EstadoReserva.terminada:
        return 'Terminada';
      case EstadoReserva.cancelada:
        return 'Cancelada';
    }
  }

  /// Una reserva "viva": todavía puede ocurrir (y por tanto cancelarse).
  bool get esActiva => this == EstadoReserva.pendiente || this == EstadoReserva.aceptada;
}

/// Reserva de celda tal como la devuelve `GET /reservas/...`: además de los
/// ids trae `celda {numero, parqueadero}` y `vehiculo {placa}` ya resueltos.
class Reserva {
  final int id;
  final EstadoReserva estado;
  final String tipoReserva;
  final int? celdaId;
  final String celdaNumero;
  final int? parqueaderoId;
  final int? vehiculoId;
  final String placa;
  final String? motivo;
  final String? motivoRechazo;
  final DateTime inicio;
  final DateTime fin;

  const Reserva({
    required this.id,
    required this.estado,
    required this.tipoReserva,
    required this.celdaId,
    required this.celdaNumero,
    required this.parqueaderoId,
    required this.vehiculoId,
    required this.placa,
    required this.motivo,
    required this.motivoRechazo,
    required this.inicio,
    required this.fin,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    final celda = json['celda'];
    final vehiculo = json['vehiculo'];
    return Reserva(
      id: json['id'] as int,
      estado: EstadoReservaApi.desdeApi(json['estado'] as String?),
      tipoReserva: (json['tipo_reserva'] as String?) ?? 'VEHICULO_SENA',
      celdaId: json['celda_id'] as int?,
      celdaNumero: celda is Map ? (celda['numero']?.toString() ?? '—') : '—',
      parqueaderoId: celda is Map ? celda['parqueadero'] as int? : null,
      vehiculoId: json['vehiculo_id'] as int?,
      placa: vehiculo is Map ? (vehiculo['placa']?.toString() ?? '—') : '—',
      motivo: json['motivo'] as String?,
      motivoRechazo: json['motivo_rechazo'] as String?,
      // Las fechas llegan en UTC (ISO 8601); se pasan a hora local para mostrar.
      inicio: (DateTime.tryParse(json['fecha_hora_inicio']?.toString() ?? '') ?? DateTime.now()).toLocal(),
      fin: (DateTime.tryParse(json['fecha_hora_fin']?.toString() ?? '') ?? DateTime.now()).toLocal(),
    );
  }
}

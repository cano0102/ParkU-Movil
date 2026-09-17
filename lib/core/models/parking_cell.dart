import 'vehicle.dart';

enum CellStatus { libre, ocupada, reserva, mantenimiento }

extension CellStatusApi on CellStatus {
  static CellStatus desdeApi(String? valor) {
    switch ((valor ?? '').toUpperCase()) {
      case 'OCUPADA':
        return CellStatus.ocupada;
      case 'RESERVADA':
        return CellStatus.reserva;
      case 'MANTENIMIENTO':
      // INACTIVA no tiene equivalente propio en la app: se muestra como
      // mantenimiento (en ambos casos la celda no se puede asignar).
      case 'INACTIVA':
        return CellStatus.mantenimiento;
      default:
        return CellStatus.libre;
    }
  }
}

/// Usabilidad de una celda en Api-ParkU (`usabilidad_enum`). Una celda
/// preferencial (movilidad reducida) solo admite conductores con esa
/// condición registrada: la base de datos rechaza el ingreso o la reserva
/// de cualquier otro, así que conviene verla distinta en el mapa.
enum CellUsability { general, ejecutivo, movilidadReducida, vehiculoSena }

extension CellUsabilityApi on CellUsability {
  static CellUsability desdeApi(String? valor) {
    switch ((valor ?? '').toUpperCase()) {
      case 'EJECUTIVO':
        return CellUsability.ejecutivo;
      case 'MOVILIDAD_REDUCIDA':
        return CellUsability.movilidadReducida;
      case 'VEHICULO_SENA':
        return CellUsability.vehiculoSena;
      default:
        return CellUsability.general;
    }
  }

  /// Etiqueta corta para la casilla del mapa; vacía para una celda normal.
  String get insignia {
    switch (this) {
      case CellUsability.general:
        return '';
      case CellUsability.ejecutivo:
        return 'EJEC';
      case CellUsability.movilidadReducida:
        return 'PMR';
      case CellUsability.vehiculoSena:
        return 'SENA';
    }
  }

  String get label {
    switch (this) {
      case CellUsability.general:
        return 'General';
      case CellUsability.ejecutivo:
        return 'Ejecutivo';
      case CellUsability.movilidadReducida:
        return 'Movilidad reducida';
      case CellUsability.vehiculoSena:
        return 'Vehículo SENA';
    }
  }

  bool get esPreferencial => this != CellUsability.general;
}

/// Una celda física de un parqueadero, con su ocupante si aplica.
///
/// Para vigilante/admin el ocupante llega de una vez con la celda
/// (`GET /monitoreo/celdas` trae `ocupacion {vehiculo, conductor, ...}`).
/// Para un conductor, `GET /celdas` solo trae el estado: [placa],
/// [conductorNombre] y [desde] se completan aparte solo para sus propios
/// vehículos (ver ParkingRepository).
class ParkingCell {
  final int? id;
  final String codigo;
  final VehicleType tipo;
  final CellUsability usabilidad;
  final int? parqueaderoId;
  final String? parqueaderoNombre;
  CellStatus estado;
  String? placa;
  String? conductorNombre;
  String? conductorRol;
  DateTime? desde;

  /// Solo al elegir celda para un ingreso (`/celdas/.../disponibles?vehiculo_id=`):
  /// `true` si la API la marcó como la reservada para ese vehículo.
  bool reservadaParaVehiculo = false;

  /// Solo al elegir celda para un ingreso: `true` si está DISPONIBLE pero la
  /// API no la ofrece porque una reserva de otro vehículo la retiene ahora
  /// o en menos de dos horas.
  bool retenidaPorReserva = false;

  ParkingCell({
    this.id,
    required this.codigo,
    this.tipo = VehicleType.carro,
    this.usabilidad = CellUsability.general,
    this.parqueaderoId,
    this.parqueaderoNombre,
    this.estado = CellStatus.libre,
    this.placa,
    this.conductorNombre,
    this.conductorRol,
    this.desde,
  });

  /// Acepta tanto la forma de `/celdas` (`parqueadero`, `parqueadero_nombre`)
  /// como la de `/monitoreo/celdas` (`parqueadero_id`, `parqueadero_nombre`,
  /// `ocupacion`).
  factory ParkingCell.fromJson(Map<String, dynamic> json) {
    final celda = ParkingCell(
      id: json['id'] as int?,
      codigo: (json['numero'] as String?) ?? '${json['id']}',
      tipo: VehicleTypeLabel.desdeApi(json['tipo'] as String?),
      usabilidad: CellUsabilityApi.desdeApi(json['usabilidad'] as String?),
      parqueaderoId: (json['parqueadero_id'] ?? json['parqueadero']) as int?,
      parqueaderoNombre: json['parqueadero_nombre'] as String?,
      estado: CellStatusApi.desdeApi(json['estado'] as String?),
    );
    celda.reservadaParaVehiculo = json['reservada_para_este_vehiculo'] == true;
    final ocupacion = json['ocupacion'];
    if (ocupacion is Map<String, dynamic>) {
      final vehiculo = ocupacion['vehiculo'];
      final conductor = ocupacion['conductor'];
      celda.estado = CellStatus.ocupada;
      celda.placa = vehiculo is Map ? vehiculo['placa']?.toString() : null;
      celda.conductorNombre = conductor is Map ? conductor['nombre']?.toString() : null;
      final ingreso = ocupacion['fecha_hora_ingreso']?.toString();
      celda.desde = ingreso != null ? DateTime.tryParse(ingreso)?.toLocal() : null;
    }
    return celda;
  }

  /// "A-01 · Sótano C" cuando se conoce el parqueadero; solo "A-01" si no.
  String get codigoConParqueadero => parqueaderoNombre == null ? codigo : '$codigo · $parqueaderoNombre';

  bool get esLibre => estado == CellStatus.libre;
  bool get esOcupada => estado == CellStatus.ocupada;
  bool get esBloqueada => estado == CellStatus.reserva || estado == CellStatus.mantenimiento;

  /// Se le puede asignar al vehículo que se está ingresando: la celda que
  /// tiene reservada (aunque figure RESERVADA) o una libre que la API sí
  /// ofrece (no retenida por una reserva ajena).
  bool get esAsignable => reservadaParaVehiculo || (esLibre && !retenidaPorReserva);

  Duration? get permanencia => desde == null ? null : DateTime.now().difference(desde!);
}

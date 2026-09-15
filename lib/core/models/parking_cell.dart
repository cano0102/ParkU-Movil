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

/// Una celda física del parqueadero, con su ocupante si aplica.
///
/// Api-ParkU no incluye el ocupante en `GET /celdas/...` (solo el estado):
/// [placa]/[conductorNombre]/[desde] se completan aparte, consultando
/// `/ocupaciones/celda/:id` + `/vehiculos/:id` solo cuando se necesitan
/// (al abrir el detalle de una celda ocupada), no al cargar el mapa completo.
class ParkingCell {
  final int? id;
  final String codigo;
  CellStatus estado;
  String? placa;
  String? conductorNombre;
  String? conductorRol;
  DateTime? desde;

  ParkingCell({
    this.id,
    required this.codigo,
    this.estado = CellStatus.libre,
    this.placa,
    this.conductorNombre,
    this.conductorRol,
    this.desde,
  });

  factory ParkingCell.fromJson(Map<String, dynamic> json) {
    return ParkingCell(
      id: json['id'] as int?,
      codigo: (json['numero'] as String?) ?? '${json['id']}',
      estado: CellStatusApi.desdeApi(json['estado'] as String?),
    );
  }

  bool get esLibre => estado == CellStatus.libre;
  bool get esOcupada => estado == CellStatus.ocupada;
  bool get esBloqueada => estado == CellStatus.reserva || estado == CellStatus.mantenimiento;

  Duration? get permanencia => desde == null ? null : DateTime.now().difference(desde!);
}

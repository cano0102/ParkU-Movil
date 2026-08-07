enum CellStatus { libre, ocupada, reserva, mantenimiento }

/// Una celda física del parqueadero, con su ocupante si aplica.
class ParkingCell {
  final String codigo;
  CellStatus estado;
  String? placa;
  String? conductorNombre;
  String? conductorRol;
  DateTime? desde;

  ParkingCell({
    required this.codigo,
    this.estado = CellStatus.libre,
    this.placa,
    this.conductorNombre,
    this.conductorRol,
    this.desde,
  });

  bool get esLibre => estado == CellStatus.libre;
  bool get esOcupada => estado == CellStatus.ocupada;
  bool get esBloqueada => estado == CellStatus.reserva || estado == CellStatus.mantenimiento;

  Duration? get permanencia => desde == null ? null : DateTime.now().difference(desde!);
}

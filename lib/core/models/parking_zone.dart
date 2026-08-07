import 'parking_cell.dart';
import 'vehicle.dart';

/// Una zona del parqueadero (carros, motos o camiones) y su mapa de celdas.
class ParkingZone {
  final String etiqueta;
  final VehicleType tipo;
  final List<ParkingCell> celdas;

  ParkingZone({
    required this.etiqueta,
    required this.tipo,
    required this.celdas,
  });

  int get capacidad => celdas.length;
  int get ocupados => celdas.where((c) => c.esOcupada).length;
  int get disponibles => celdas.where((c) => c.esLibre).length;
}

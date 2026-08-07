import 'vehicle.dart';

/// Ocupación de una zona del parqueadero (carros, motos o camiones).
class ParkingZone {
  final String etiqueta;
  final VehicleType tipo;
  int ocupados;
  final int capacidad;

  ParkingZone({
    required this.etiqueta,
    required this.tipo,
    required this.ocupados,
    required this.capacidad,
  });

  int get disponibles => capacidad - ocupados;
}

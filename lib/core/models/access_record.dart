enum AccessStatus { dentro, salio, novedad }

/// Un movimiento del historial (ingreso, salida o novedad).
class AccessRecord {
  final String placa;
  final String detalle;
  final DateTime hora;
  final AccessStatus estado;

  const AccessRecord({
    required this.placa,
    required this.detalle,
    required this.hora,
    required this.estado,
  });

  String get estadoLabel {
    switch (estado) {
      case AccessStatus.dentro:
        return 'Dentro';
      case AccessStatus.salio:
        return 'Salió';
      case AccessStatus.novedad:
        return 'Novedad';
    }
  }
}

/// Vehículo actualmente dentro del parqueadero.
class ParkedVehicle {
  final String placa;
  final String conductorNombre;
  final String celda;
  final DateTime horaIngreso;

  const ParkedVehicle({
    required this.placa,
    required this.conductorNombre,
    required this.celda,
    required this.horaIngreso,
  });

  Duration get permanencia => DateTime.now().difference(horaIngreso);
}

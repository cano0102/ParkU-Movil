enum AccessStatus { dentro, salio, novedad }

/// Un movimiento del historial: una estadía en el parqueadero (ingreso y,
/// si ya salió, salida) o una novedad.
///
/// Para el vigilante viene de `registro_acceso` (`/entradas-salidas/filtro`);
/// para el conductor, de `ocupacion_celda` (`/ocupaciones/vehiculo/:id`), que
/// es lo único de esto que la API le deja consultar. Ambas fuentes traen la
/// celda y las dos horas, que es lo que la persona quiere ver.
class AccessRecord {
  final String placa;

  /// Texto libre: la descripción de una novedad. Para una estadía va vacío;
  /// la tarjeta arma el texto con [celda], [ingreso] y [salida].
  final String detalle;

  /// Momento por el que se ordena y filtra: la salida si ya ocurrió, si no
  /// el ingreso; en una novedad, su fecha.
  final DateTime hora;
  final AccessStatus estado;

  final String? celda;
  final String? parqueadero;
  final DateTime? ingreso;
  final DateTime? salida;
  final String? conductor;

  const AccessRecord({
    required this.placa,
    this.detalle = '',
    required this.hora,
    required this.estado,
    this.celda,
    this.parqueadero,
    this.ingreso,
    this.salida,
    this.conductor,
  });

  /// Estadía (ingreso/salida) a partir de sus datos; [hora] se deduce.
  factory AccessRecord.estadia({
    required String placa,
    required DateTime ingreso,
    DateTime? salida,
    String? celda,
    String? parqueadero,
    String? conductor,
    bool bloqueado = false,
  }) {
    return AccessRecord(
      placa: placa,
      hora: salida ?? ingreso,
      estado: bloqueado
          ? AccessStatus.novedad
          : salida == null
          ? AccessStatus.dentro
          : AccessStatus.salio,
      celda: celda,
      parqueadero: parqueadero,
      ingreso: ingreso,
      salida: salida,
      conductor: conductor,
    );
  }

  bool get esEstadia => ingreso != null;

  /// "M-01 · Sótano C", solo "M-01" si no se conoce el parqueadero, o null.
  String? get celdaConParqueadero {
    if (celda == null) return null;
    return parqueadero == null ? celda : '$celda · $parqueadero';
  }

  /// Tiempo dentro: hasta la salida, o hasta ahora si sigue adentro.
  Duration? get permanencia => ingreso == null ? null : (salida ?? DateTime.now()).difference(ingreso!);

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

  const ParkedVehicle({required this.placa, required this.conductorNombre, required this.celda, required this.horaIngreso});

  Duration get permanencia => DateTime.now().difference(horaIngreso);
}

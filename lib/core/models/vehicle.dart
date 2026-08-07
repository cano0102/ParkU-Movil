enum VehicleType { carro, moto, camion }

extension VehicleTypeLabel on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.carro:
        return 'Carro';
      case VehicleType.moto:
        return 'Moto';
      case VehicleType.camion:
        return 'Camión';
    }
  }

  String get zona {
    switch (this) {
      case VehicleType.carro:
        return 'Zona A';
      case VehicleType.moto:
        return 'Zona B';
      case VehicleType.camion:
        return 'Zona C';
    }
  }
}

/// Vehículo registrado en el sistema, con los datos de su conductor.
class Vehicle {
  final String placa;
  final VehicleType tipo;
  final String marcaLinea;
  final String color;
  final bool soatVigente;
  final String conductorNombre;
  final String conductorRol;
  final String conductorDocumento;

  const Vehicle({
    required this.placa,
    required this.tipo,
    required this.marcaLinea,
    required this.color,
    required this.soatVigente,
    required this.conductorNombre,
    required this.conductorRol,
    required this.conductorDocumento,
  });

  String get iniciales {
    final partes = conductorNombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return (partes[0][0] + partes[1][0]).toUpperCase();
    }
    return partes.isNotEmpty ? partes[0].substring(0, 1).toUpperCase() : '?';
  }
}

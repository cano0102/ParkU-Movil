// Api-ParkU solo admite estos dos tipos de vehículo (ver enum CARRO|MOTO en
// vehiculo.controller.js / celda.controller.js): no hay zona de camiones.
enum VehicleType { carro, moto }

extension VehicleTypeLabel on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.carro:
        return 'Carro';
      case VehicleType.moto:
        return 'Moto';
    }
  }

  String get zona {
    switch (this) {
      case VehicleType.carro:
        return 'Zona A';
      case VehicleType.moto:
        return 'Zona B';
    }
  }

  /// Valor que espera la API en el campo `tipo` (CARRO|MOTO).
  String get apiValue {
    switch (this) {
      case VehicleType.carro:
        return 'CARRO';
      case VehicleType.moto:
        return 'MOTO';
    }
  }

  static VehicleType desdeApi(String? valor) {
    switch ((valor ?? '').toUpperCase()) {
      case 'MOTO':
        return VehicleType.moto;
      default:
        return VehicleType.carro;
    }
  }
}

/// Vehículo registrado en Api-ParkU, con los datos de su conductor
/// principal que trae el propio endpoint (`conductor_principal_*`).
class Vehicle {
  final int? id;
  /// id del Conductor propietario (conductor_principal_id), para poder
  /// resolver aparte su documento/tipo de usuario si se necesita mostrar
  /// (ver ParkingRepository.buscarVehiculo). No lo expone la UI directamente.
  final int? conductorPrincipalId;
  final String placa;
  final VehicleType tipo;
  final String marcaLinea;
  final String color;
  // Api-ParkU no registra el estado del SOAT en el vehículo: no hay campo
  // real que consultar, así que se muestra siempre vigente.
  final bool soatVigente;
  final String conductorNombre;
  final String conductorRol;
  final String conductorDocumento;

  const Vehicle({
    this.id,
    this.conductorPrincipalId,
    required this.placa,
    required this.tipo,
    required this.marcaLinea,
    required this.color,
    required this.soatVigente,
    required this.conductorNombre,
    required this.conductorRol,
    required this.conductorDocumento,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final marca = (json['marca'] as String?)?.trim() ?? '';
    final linea = (json['linea'] as String?)?.trim() ?? '';
    return Vehicle(
      id: json['id'] as int?,
      conductorPrincipalId: json['conductor_principal_id'] as int?,
      placa: (json['placa'] as String?) ?? '',
      tipo: VehicleTypeLabel.desdeApi(json['tipo'] as String?),
      marcaLinea: [marca, linea].where((s) => s.isNotEmpty).join(' '),
      color: (json['color'] as String?) ?? '',
      soatVigente: true,
      conductorNombre: (json['conductor_principal_nombre'] as String?) ?? 'Sin conductor asociado',
      conductorRol: 'Conductor',
      conductorDocumento: '—',
    );
  }

  Vehicle copyWith({String? conductorRol, String? conductorDocumento}) {
    return Vehicle(
      id: id,
      conductorPrincipalId: conductorPrincipalId,
      placa: placa,
      tipo: tipo,
      marcaLinea: marcaLinea,
      color: color,
      soatVigente: soatVigente,
      conductorNombre: conductorNombre,
      conductorRol: conductorRol ?? this.conductorRol,
      conductorDocumento: conductorDocumento ?? this.conductorDocumento,
    );
  }

  String get iniciales {
    final partes = conductorNombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) {
      return (partes[0][0] + partes[1][0]).toUpperCase();
    }
    return partes.isNotEmpty ? partes[0].substring(0, 1).toUpperCase() : '?';
  }
}

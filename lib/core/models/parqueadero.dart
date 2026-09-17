/// Un parqueadero de Api-ParkU (`GET /parqueaderos`). La app trabaja con
/// todos los activos a la vez: el mapa agrupa sus celdas por tipo de
/// vehículo y el conductor elige uno al pedir una reserva.
///
/// `hora_apertura`/`hora_cierre` y `capacidad_maxima` no se leen a propósito:
/// la API tampoco los aplica (usa el horario global de operación y las
/// celdas reales), así que mostrarlos daría una idea falsa de las reglas.
class Parqueadero {
  final int id;
  final String nombre;
  final String? ubicacion;
  final String tipo;
  final bool activo;

  const Parqueadero({required this.id, required this.nombre, this.ubicacion, this.tipo = 'GENERAL', this.activo = true});

  factory Parqueadero.fromJson(Map<String, dynamic> json) {
    final nombre = (json['nombre'] as String?)?.trim();
    final estado = json['estado'];
    return Parqueadero(
      id: json['id'] as int,
      nombre: (nombre == null || nombre.isEmpty) ? 'Parqueadero ${json['id']}' : nombre,
      ubicacion: json['ubicacion'] as String?,
      tipo: (json['tipo'] as String?)?.toUpperCase() ?? 'GENERAL',
      // La API guarda el estado como booleano (y añade estado_texto); se
      // tolera un texto por si acaso.
      activo: estado is bool ? estado : estado == null || estado.toString().toUpperCase() == 'ACTIVO' || estado.toString() == 'true',
    );
  }

  /// Etiqueta legible del `tipo` (enum de la API); vacía para GENERAL.
  String get tipoLabel {
    switch (tipo) {
      case 'DOCENTES':
        return 'Docentes';
      case 'ADMINISTRATIVOS':
        return 'Administrativos';
      case 'APRENDICES':
        return 'Aprendices';
      case 'VISITANTES':
        return 'Visitantes';
      case 'MOTOS':
        return 'Motos';
      case 'VEHICULO_SENA':
        return 'Vehículos SENA';
      default:
        return '';
    }
  }

  /// "Parqueadero Docentes · Docentes" no aporta; "Sótano C · General" tampoco.
  /// Solo se añade el tipo cuando dice algo que el nombre no dice.
  String get nombreConTipo {
    final etiqueta = tipoLabel;
    if (etiqueta.isEmpty || nombre.toLowerCase().contains(etiqueta.toLowerCase())) return nombre;
    return '$nombre · $etiqueta';
  }
}

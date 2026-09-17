/// Turno de un vigilante en un parqueadero, tal como lo devuelve
/// `GET /asignaciones-vigilante/usuario/:usuarioId` (con `parqueadero
/// {id, nombre}` ya resuelto). Es lo que la app muestra como "portería" y
/// "turno" del guarda.
class AsignacionVigilante {
  final int id;
  final int parqueaderoId;
  final String parqueaderoNombre;
  final String turno;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? horaInicio;
  final String? horaFin;
  final bool activa;

  const AsignacionVigilante({
    required this.id,
    required this.parqueaderoId,
    required this.parqueaderoNombre,
    required this.turno,
    required this.fechaInicio,
    required this.fechaFin,
    required this.horaInicio,
    required this.horaFin,
    required this.activa,
  });

  factory AsignacionVigilante.fromJson(Map<String, dynamic> json) {
    final parqueadero = json['parqueadero'];
    final estado = json['estado'];
    return AsignacionVigilante(
      id: json['id'] as int,
      parqueaderoId: json['parqueadero_id'] as int,
      parqueaderoNombre: parqueadero is Map ? (parqueadero['nombre']?.toString() ?? '—') : '—',
      turno: (json['turno'] as String?)?.toUpperCase() ?? '',
      fechaInicio: _fecha(json['fecha_inicio']),
      fechaFin: _fecha(json['fecha_fin']),
      horaInicio: _hora(json['hora_inicio']),
      horaFin: _hora(json['hora_fin']),
      activa: estado is bool ? estado : estado == null || estado.toString() == 'true',
    );
  }

  /// `fecha_inicio`/`fecha_fin` son DATE ("2026-07-01"); se leen como día
  /// local para compararlos con "hoy" sin que la zona horaria los corra.
  static DateTime? _fecha(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString();
    final soloFecha = texto.length >= 10 ? texto.substring(0, 10) : texto;
    final partes = soloFecha.split('-');
    if (partes.length != 3) return null;
    final y = int.tryParse(partes[0]), m = int.tryParse(partes[1]), d = int.tryParse(partes[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// `hora_inicio` es TIME ("06:00:00") → "06:00".
  static String? _hora(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString();
    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  /// Vigente hoy: activa, ya empezó y no ha terminado.
  bool vigenteEn(DateTime dia) {
    if (!activa) return false;
    final hoy = DateTime(dia.year, dia.month, dia.day);
    if (fechaInicio != null && fechaInicio!.isAfter(hoy)) return false;
    if (fechaFin != null && fechaFin!.isBefore(hoy)) return false;
    return true;
  }

  /// true si la hora dada cae dentro del horario del turno (o no hay horas).
  bool cubreHora(DateTime momento) {
    final inicio = _minutos(horaInicio);
    final fin = _minutos(horaFin);
    if (inicio == null || fin == null) return true;
    final ahora = momento.hour * 60 + momento.minute;
    // Un turno de noche puede cruzar la medianoche (22:00–06:00).
    return inicio <= fin ? ahora >= inicio && ahora < fin : ahora >= inicio || ahora < fin;
  }

  static int? _minutos(String? hhmm) {
    if (hhmm == null) return null;
    final partes = hhmm.split(':');
    if (partes.length < 2) return null;
    final h = int.tryParse(partes[0]), m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  String get turnoLabel {
    switch (turno) {
      case 'MANANA':
        return 'Mañana';
      case 'TARDE':
        return 'Tarde';
      case 'NOCHE':
        return 'Noche';
      default:
        return turno.isEmpty ? 'Turno' : turno;
    }
  }

  /// "Mañana · 06:00–14:00" (o solo "Mañana" si no hay horas).
  String get turnoConHoras {
    if (horaInicio == null || horaFin == null) return turnoLabel;
    return '$turnoLabel · $horaInicio–$horaFin';
  }
}

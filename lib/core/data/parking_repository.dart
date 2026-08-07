import 'package:flutter/foundation.dart';
import '../models/access_record.dart';
import '../models/parking_zone.dart';
import '../models/vehicle.dart';

/// Fuente única de datos de la app (en memoria).
///
/// Sustituye a un backend real: guarda el estado de ocupación, el
/// historial de movimientos y los vehículos actualmente dentro, para que
/// las 9 pantallas del módulo de portería compartan la misma información.
class ParkingRepository extends ChangeNotifier {
  ParkingRepository._internal() {
    _seed();
  }

  static final ParkingRepository instance = ParkingRepository._internal();

  final String sede = 'Complejo Central · Regional Antioquia';
  final String guardaNombre = 'Anderson Arboleda';
  final String guardaCorreo = 'aarboleda@sena.edu.co';
  final String guardaRol = 'Guarda de portería · Vigilancia';
  final String porteria = 'Norte';
  final String turno = '6:00 – 14:00';

  bool alertasNoAutorizados = true;
  bool modoSinConexion = true;
  int registrosPendientesSync = 3;

  final List<ParkingZone> zonas = [
    ParkingZone(etiqueta: 'Carros', tipo: VehicleType.carro, ocupados: 62, capacidad: 80),
    ParkingZone(etiqueta: 'Motos', tipo: VehicleType.moto, ocupados: 44, capacidad: 60),
    ParkingZone(etiqueta: 'Camiones', tipo: VehicleType.camion, ocupados: 9, capacidad: 10),
  ];

  int get cuposDisponibles => zonas.fold(0, (sum, z) => sum + z.disponibles);
  int get cuposTotales => zonas.fold(0, (sum, z) => sum + z.capacidad);

  final Map<String, Vehicle> _vehiculosRegistrados = {};
  final Map<String, ParkedVehicle> _dentro = {};
  final List<AccessRecord> historial = [];

  int _celdaSeq = 25;

  void _seed() {
    final registrados = <Vehicle>[
      const Vehicle(
        placa: 'WGY482',
        tipo: VehicleType.carro,
        marcaLinea: 'Mazda 3',
        color: 'Gris',
        soatVigente: true,
        conductorNombre: 'Mateo Bejarano Mejía',
        conductorRol: 'Aprendiz · Ficha 2879654',
        conductorDocumento: 'C.C. 1.036.***.412',
      ),
      const Vehicle(
        placa: 'JKD09E',
        tipo: VehicleType.carro,
        marcaLinea: 'Renault Logan',
        color: 'Blanco',
        soatVigente: true,
        conductorNombre: 'Valery Restrepo',
        conductorRol: 'Instructora · Sistemas',
        conductorDocumento: 'C.C. 1.017.***.208',
      ),
      const Vehicle(
        placa: 'HRT340',
        tipo: VehicleType.moto,
        marcaLinea: 'AKT NKD 125',
        color: 'Negro',
        soatVigente: true,
        conductorNombre: 'Santiago Tobón',
        conductorRol: 'Aprendiz · Ficha 2765310',
        conductorDocumento: 'C.C. 1.028.***.771',
      ),
      const Vehicle(
        placa: 'LNC55A',
        tipo: VehicleType.camion,
        marcaLinea: 'Chevrolet NHR',
        color: 'Azul',
        soatVigente: true,
        conductorNombre: 'Carlos Quintero',
        conductorRol: 'Proveedor · Logística',
        conductorDocumento: 'C.C. 1.045.***.902',
      ),
    ];
    for (final v in registrados) {
      _vehiculosRegistrados[v.placa] = v;
    }

    final ahora = DateTime.now();
    historial.addAll([
      AccessRecord(
        placa: 'WGY 482',
        detalle: 'Ingreso · Celda A-24 · M. Bejarano',
        hora: ahora.subtract(const Duration(minutes: 3)),
        estado: AccessStatus.dentro,
      ),
      AccessRecord(
        placa: 'JKD 09E',
        detalle: 'Salida · 2 h 05 min · V. Restrepo',
        hora: ahora.subtract(const Duration(minutes: 10)),
        estado: AccessStatus.salio,
      ),
      AccessRecord(
        placa: 'TQP 71D',
        detalle: 'Denegado · sin registro',
        hora: ahora.subtract(const Duration(minutes: 29)),
        estado: AccessStatus.novedad,
      ),
      AccessRecord(
        placa: 'HRT 340',
        detalle: 'Ingreso · Celda B-11 · S. Tobón',
        hora: ahora.subtract(const Duration(minutes: 44)),
        estado: AccessStatus.dentro,
      ),
      AccessRecord(
        placa: 'MTG 18C',
        detalle: 'Ingreso · Visitante · Zona D',
        hora: ahora.subtract(const Duration(minutes: 57)),
        estado: AccessStatus.dentro,
      ),
      AccessRecord(
        placa: 'FBQ 902',
        detalle: 'Salida · 1 h 12 min · B. Quintero',
        hora: ahora.subtract(const Duration(hours: 1, minutes: 21)),
        estado: AccessStatus.salio,
      ),
      AccessRecord(
        placa: 'LNC 55A',
        detalle: 'Ingreso · Celda C-03 · Camión',
        hora: ahora.subtract(const Duration(hours: 1, minutes: 43)),
        estado: AccessStatus.dentro,
      ),
    ]);

    _dentro['WGY482'] = ParkedVehicle(
      placa: 'WGY 482',
      conductorNombre: 'Mateo Bejarano Mejía',
      celda: 'A-24',
      horaIngreso: ahora.subtract(const Duration(minutes: 3)),
    );
    _dentro['HRT340'] = ParkedVehicle(
      placa: 'HRT 340',
      conductorNombre: 'Santiago Tobón',
      celda: 'B-11',
      horaIngreso: ahora.subtract(const Duration(minutes: 44)),
    );
    _dentro['LNC55A'] = ParkedVehicle(
      placa: 'LNC 55A',
      conductorNombre: 'Carlos Quintero',
      celda: 'C-03',
      horaIngreso: ahora.subtract(const Duration(hours: 1, minutes: 43)),
    );
    // JKD09E ya salió, no queda "dentro".
  }

  static String normaliza(String placa) => placa.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String formatea(String placaNormalizada) {
    if (placaNormalizada.length <= 3) return placaNormalizada;
    return '${placaNormalizada.substring(0, 3)} ${placaNormalizada.substring(3)}';
  }

  Vehicle? buscarVehiculo(String placa) => _vehiculosRegistrados[normaliza(placa)];

  ParkedVehicle? buscarDentro(String placa) => _dentro[normaliza(placa)];

  List<AccessRecord> historialFiltrado(String filtro) {
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
    switch (filtro) {
      case 'Ayer':
        final ayerInicio = hoyInicio.subtract(const Duration(days: 1));
        return historial.where((r) => r.hora.isAfter(ayerInicio) && r.hora.isBefore(hoyInicio)).toList();
      case '7 días':
        final hace7 = ahora.subtract(const Duration(days: 7));
        return historial.where((r) => r.hora.isAfter(hace7)).toList();
      case 'Hoy':
      default:
        return historial.where((r) => r.hora.isAfter(hoyInicio)).toList();
    }
  }

  String registrarIngreso(Vehicle vehicle) {
    final zona = zonas.firstWhere((z) => z.tipo == vehicle.tipo);
    zona.ocupados = (zona.ocupados + 1).clamp(0, zona.capacidad);
    _celdaSeq++;
    final prefijo = vehicle.tipo == VehicleType.carro
        ? 'A'
        : vehicle.tipo == VehicleType.moto
            ? 'B'
            : 'C';
    final celda = '$prefijo-${_celdaSeq.toString().padLeft(2, '0')}';
    final placaFormateada = formatea(vehicle.placa);

    _dentro[vehicle.placa] = ParkedVehicle(
      placa: placaFormateada,
      conductorNombre: vehicle.conductorNombre,
      celda: celda,
      horaIngreso: DateTime.now(),
    );

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Celda $celda · ${vehicle.conductorNombre}',
        hora: DateTime.now(),
        estado: AccessStatus.dentro,
      ),
    );
    notifyListeners();
    return celda;
  }

  void registrarSalida(String placa) {
    final normalizada = normaliza(placa);
    final parked = _dentro.remove(normalizada);
    final placaFormateada = parked?.placa ?? formatea(normalizada);
    final vehicle = _vehiculosRegistrados[normalizada];
    if (vehicle != null) {
      final zona = zonas.firstWhere((z) => z.tipo == vehicle.tipo);
      zona.ocupados = (zona.ocupados - 1).clamp(0, zona.capacidad);
    }
    final permanencia = parked != null ? _formatDuration(parked.permanencia) : '--';
    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Salida · $permanencia${parked != null ? ' · ${parked.conductorNombre}' : ''}',
        hora: DateTime.now(),
        estado: AccessStatus.salio,
      ),
    );
    notifyListeners();
  }

  void registrarDenegado(String placa) {
    historial.insert(
      0,
      AccessRecord(
        placa: formatea(normaliza(placa)),
        detalle: 'Denegado · sin registro',
        hora: DateTime.now(),
        estado: AccessStatus.novedad,
      ),
    );
    notifyListeners();
  }

  void registrarVisitante(String placa) {
    final zona = zonas.firstWhere((z) => z.tipo == VehicleType.carro);
    zona.ocupados = (zona.ocupados + 1).clamp(0, zona.capacidad);
    final placaFormateada = formatea(normaliza(placa));
    _dentro[normaliza(placa)] = ParkedVehicle(
      placa: placaFormateada,
      conductorNombre: 'Visitante',
      celda: 'D-VIS',
      horaIngreso: DateTime.now(),
    );
    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Visitante · Zona D',
        hora: DateTime.now(),
        estado: AccessStatus.dentro,
      ),
    );
    notifyListeners();
  }

  void actualizarAlertas(bool valor) {
    alertasNoAutorizados = valor;
    notifyListeners();
  }

  void actualizarModoSinConexion(bool valor) {
    modoSinConexion = valor;
    notifyListeners();
  }

  void sincronizar() {
    registrosPendientesSync = 0;
    notifyListeners();
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }
}

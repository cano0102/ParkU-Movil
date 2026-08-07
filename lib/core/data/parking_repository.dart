import 'dart:math';

import 'package:flutter/foundation.dart';
import '../models/access_record.dart';
import '../models/parking_cell.dart';
import '../models/parking_zone.dart';
import '../models/vehicle.dart';

/// Fuente única de datos de la app (en memoria).
///
/// Sustituye a un backend real: guarda el mapa de celdas por zona, el
/// historial de movimientos y los vehículos registrados, para que todas
/// las pantallas del módulo de portería (incluido el mapa del
/// parqueadero) compartan la misma información. La ocupación de cada
/// zona se calcula siempre a partir de sus celdas, nunca de un contador
/// aparte, para que no se puedan desincronizar.
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

  late final List<ParkingZone> zonas;

  int get cuposDisponibles => zonas.fold(0, (sum, z) => sum + z.disponibles);
  int get cuposTotales => zonas.fold(0, (sum, z) => sum + z.capacidad);

  final Map<String, Vehicle> _vehiculosRegistrados = {};
  final List<AccessRecord> historial = [];

  static const _rolesGenericos = ['Aprendiz', 'Instructor', 'Funcionario', 'Contratista', 'Visitante'];
  static const _apellidosGenericos = [
    'Gómez', 'Ramírez', 'Torres', 'Vélez', 'Ospina', 'Cardona', 'Zapata', 'Muñoz',
    'Correa', 'Giraldo', 'Londoño', 'Betancur', 'Salazar', 'Marín', 'Henao',
  ];

  void _seed() {
    const wgy482 = Vehicle(
      placa: 'WGY482',
      tipo: VehicleType.carro,
      marcaLinea: 'Mazda 3',
      color: 'Gris',
      soatVigente: true,
      conductorNombre: 'Mateo Bejarano Mejía',
      conductorRol: 'Aprendiz · Ficha 2879654',
      conductorDocumento: 'C.C. 1.036.***.412',
    );
    const jkd09e = Vehicle(
      placa: 'JKD09E',
      tipo: VehicleType.carro,
      marcaLinea: 'Renault Logan',
      color: 'Blanco',
      soatVigente: true,
      conductorNombre: 'Valery Restrepo',
      conductorRol: 'Instructora · Sistemas',
      conductorDocumento: 'C.C. 1.017.***.208',
    );
    const hrt340 = Vehicle(
      placa: 'HRT340',
      tipo: VehicleType.moto,
      marcaLinea: 'AKT NKD 125',
      color: 'Negro',
      soatVigente: true,
      conductorNombre: 'Santiago Tobón',
      conductorRol: 'Aprendiz · Ficha 2765310',
      conductorDocumento: 'C.C. 1.028.***.771',
    );
    const lnc55a = Vehicle(
      placa: 'LNC55A',
      tipo: VehicleType.camion,
      marcaLinea: 'Chevrolet NHR',
      color: 'Azul',
      soatVigente: true,
      conductorNombre: 'Carlos Quintero',
      conductorRol: 'Proveedor · Logística',
      conductorDocumento: 'C.C. 1.045.***.902',
    );

    for (final v in [wgy482, jkd09e, hrt340, lnc55a]) {
      _vehiculosRegistrados[v.placa] = v;
    }

    zonas = [
      ParkingZone(
        etiqueta: 'Carros',
        tipo: VehicleType.carro,
        celdas: _generarCeldas(prefijo: 'A', total: 80, ocupadas: 60, reservas: 2, mantenimiento: 1, destacadas: {24: wgy482}),
      ),
      ParkingZone(
        etiqueta: 'Motos',
        tipo: VehicleType.moto,
        celdas: _generarCeldas(prefijo: 'B', total: 60, ocupadas: 42, reservas: 1, mantenimiento: 1, destacadas: {11: hrt340}),
      ),
      ParkingZone(
        etiqueta: 'Camiones',
        tipo: VehicleType.camion,
        celdas: _generarCeldas(prefijo: 'C', total: 10, ocupadas: 7, mantenimiento: 1, destacadas: {3: lnc55a}),
      ),
    ];

    // JKD09E ya salió: queda registrada pero sin celda activa.
    final ahora = DateTime.now();
    historial.addAll([
      AccessRecord(
        placa: 'WGY 482',
        detalle: 'Ingreso · Celda A24 · M. Bejarano',
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
        detalle: 'Ingreso · Celda B11 · S. Tobón',
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
        detalle: 'Ingreso · Celda C03 · Camión',
        hora: ahora.subtract(const Duration(hours: 1, minutes: 43)),
        estado: AccessStatus.dentro,
      ),
    ]);
  }

  /// Genera las celdas de una zona. Las posiciones en [destacadas] quedan
  /// ocupadas por ese vehículo (para que la historia de la demo cuadre con
  /// el resto de la app); el resto de ocupantes y bloqueos se reparten de
  /// forma determinística (semilla fija) para que el mapa no cambie entre
  /// reconstrucciones de la pantalla.
  List<ParkingCell> _generarCeldas({
    required String prefijo,
    required int total,
    required int ocupadas,
    int reservas = 0,
    int mantenimiento = 0,
    Map<int, Vehicle> destacadas = const {},
  }) {
    final random = Random(prefijo.codeUnitAt(0) * 97 + total);

    final ocupadasIdx = <int>{...destacadas.keys};
    while (ocupadasIdx.length < ocupadas) {
      ocupadasIdx.add(random.nextInt(total) + 1);
    }

    final bloqueadasIdx = <int>{};
    while (bloqueadasIdx.length < reservas + mantenimiento) {
      final idx = random.nextInt(total) + 1;
      if (!ocupadasIdx.contains(idx)) bloqueadasIdx.add(idx);
    }
    final reservaIdx = bloqueadasIdx.take(reservas).toSet();

    return List.generate(total, (i) {
      final numero = i + 1;
      final codigo = '$prefijo${numero.toString().padLeft(2, '0')}';

      if (ocupadasIdx.contains(numero)) {
        final destacado = destacadas[numero];
        return ParkingCell(
          codigo: codigo,
          estado: CellStatus.ocupada,
          placa: destacado != null ? formatea(destacado.placa) : _placaGenerica(random),
          conductorNombre: destacado?.conductorNombre ?? _nombreGenerico(random),
          conductorRol: destacado?.conductorRol ?? _rolesGenericos[random.nextInt(_rolesGenericos.length)],
          desde: DateTime.now().subtract(Duration(minutes: 6 + random.nextInt(230))),
        );
      }
      if (bloqueadasIdx.contains(numero)) {
        return ParkingCell(codigo: codigo, estado: reservaIdx.contains(numero) ? CellStatus.reserva : CellStatus.mantenimiento);
      }
      return ParkingCell(codigo: codigo);
    });
  }

  static String _placaGenerica(Random random) {
    const letras = 'ABCEFGHJKLMNPQRSTUVWXYZ';
    final l = List.generate(3, (_) => letras[random.nextInt(letras.length)]).join();
    final n = (random.nextInt(900) + 100).toString();
    return '$l $n';
  }

  String _nombreGenerico(Random random) {
    const nombres = ['Juan', 'Laura', 'Andrés', 'Camila', 'Diego', 'Paula', 'Sebastián', 'Daniela', 'Julián', 'Natalia'];
    return '${nombres[random.nextInt(nombres.length)]} ${_apellidosGenericos[random.nextInt(_apellidosGenericos.length)]}';
  }

  static String normaliza(String placa) => placa.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String formatea(String placaNormalizada) {
    final limpia = normaliza(placaNormalizada);
    if (limpia.length <= 3) return limpia;
    return '${limpia.substring(0, 3)} ${limpia.substring(3)}';
  }

  Vehicle? buscarVehiculo(String placa) => _vehiculosRegistrados[normaliza(placa)];

  ParkingZone zonaDe(VehicleType tipo) => zonas.firstWhere((z) => z.tipo == tipo);

  /// Busca la celda que ocupa actualmente una placa, en cualquier zona.
  ParkingCell? celdaDePlaca(String placa) {
    final norm = normaliza(placa);
    for (final zona in zonas) {
      for (final celda in zona.celdas) {
        if (celda.esOcupada && normaliza(celda.placa ?? '') == norm) return celda;
      }
    }
    return null;
  }

  ParkedVehicle? buscarDentro(String placa) {
    final celda = celdaDePlaca(placa);
    if (celda == null) return null;
    return ParkedVehicle(
      placa: celda.placa!,
      conductorNombre: celda.conductorNombre ?? '—',
      celda: celda.codigo,
      horaIngreso: celda.desde ?? DateTime.now(),
    );
  }

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

  /// Registra el ingreso de [vehicle]. Si no se indica [celda], toma la
  /// primera celda libre de su zona (fallback quando no se pasó por el
  /// mapa). Devuelve el código de la celda asignada.
  String registrarIngreso(Vehicle vehicle, {ParkingCell? celda}) {
    final zona = zonaDe(vehicle.tipo);
    final destino = celda ?? zona.celdas.firstWhere((c) => c.esLibre, orElse: () => zona.celdas.first);
    final placaFormateada = formatea(vehicle.placa);

    destino.estado = CellStatus.ocupada;
    destino.placa = placaFormateada;
    destino.conductorNombre = vehicle.conductorNombre;
    destino.conductorRol = vehicle.conductorRol;
    destino.desde = DateTime.now();

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Celda ${destino.codigo} · ${vehicle.conductorNombre}',
        hora: DateTime.now(),
        estado: AccessStatus.dentro,
      ),
    );
    notifyListeners();
    return destino.codigo;
  }

  void registrarSalida(String placa) {
    final celda = celdaDePlaca(placa);
    final placaFormateada = celda?.placa ?? formatea(placa);
    final permanencia = celda?.permanencia != null ? formatDuration(celda!.permanencia!) : '--';
    final conductor = celda?.conductorNombre;

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Salida · $permanencia${conductor != null ? ' · $conductor' : ''}',
        hora: DateTime.now(),
        estado: AccessStatus.salio,
      ),
    );

    if (celda != null) {
      celda.estado = CellStatus.libre;
      celda.placa = null;
      celda.conductorNombre = null;
      celda.conductorRol = null;
      celda.desde = null;
    }
    notifyListeners();
  }

  void registrarDenegado(String placa) {
    historial.insert(
      0,
      AccessRecord(
        placa: formatea(placa),
        detalle: 'Denegado · sin registro',
        hora: DateTime.now(),
        estado: AccessStatus.novedad,
      ),
    );
    notifyListeners();
  }

  void registrarVisitante(String placa) {
    final zona = zonaDe(VehicleType.carro);
    final destino = zona.celdas.firstWhere((c) => c.esLibre, orElse: () => zona.celdas.first);
    final placaFormateada = formatea(placa);

    destino.estado = CellStatus.ocupada;
    destino.placa = placaFormateada;
    destino.conductorNombre = 'Visitante';
    destino.conductorRol = 'Visitante';
    destino.desde = DateTime.now();

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Visitante · Celda ${destino.codigo}',
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

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }
}

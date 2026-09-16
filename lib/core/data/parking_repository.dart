import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/access_record.dart';
import '../models/parking_cell.dart';
import '../models/parking_zone.dart';
import '../models/vehicle.dart';
import 'session_repository.dart';

/// Fuente única de datos de parqueadero de la app: antes eran datos de
/// ejemplo en memoria: ahora reflejan Api-ParkU real, cacheados aquí para
/// que las pantallas (que se suscriben con [addListener]) sigan leyendo
/// getters síncronos sin tener que convertir cada `build()` en async.
class ParkingRepository extends ChangeNotifier {
  ParkingRepository._internal();

  static final ParkingRepository instance = ParkingRepository._internal();

  final SessionRepository _session = SessionRepository.instance;

  int? _parqueaderoId;
  String _sede = 'ParkU';

  List<ParkingZone> zonas = const [];
  List<AccessRecord> historial = [];
  List<Vehicle> _misVehiculos = const [];

  /// Celda actual (si la hay) de cada placa normalizada del conductor con
  /// sesión activa. Api-ParkU no incluye el ocupante en `/celdas`, así que
  /// esto se resuelve aparte (ver [_cargarCeldaDeMisVehiculos]) y se cachea
  /// para que `celdaDePlaca` siga siendo síncrono, como usan las pantallas.
  final Map<String, ParkingCell> _celdaPorPlaca = {};

  /// id -> Vehiculo, para resolver placas al armar el historial sin una
  /// consulta por registro.
  Map<int, Vehicle> _vehiculosPorId = {};

  bool cargando = false;

  // ============================================================
  // Datos de sesión (antes fijos, ahora vienen de SessionRepository)
  // ============================================================

  String get sede => _sede;
  String get guardaNombre => _session.nombre ?? '—';
  String get guardaCorreo => _session.correo ?? '—';
  String get guardaRol => _session.rolNombre ?? 'Vigilante';
  // Api-ParkU no modela porterías/turnos: no hay endpoint del que leerlos.
  final String porteria = 'Principal';
  final String turno = 'Turno activo';

  String get conductorNombre => _session.nombre ?? '—';
  String get conductorCorreo => _session.correo ?? '—';
  String get conductorRolTexto => _session.rolNombre ?? 'Conductor';
  String get conductorDocumento {
    if (_session.numeroDocumento == null || _session.numeroDocumento!.isEmpty) return '—';
    return '${_session.tipoDocumento ?? ''} ${_session.numeroDocumento}'.trim();
  }

  // Preferencias locales de la app: Api-ParkU no las modela, así que viven
  // solo en este dispositivo (no se sincronizan con el backend).
  bool alertasNoAutorizados = true;
  bool modoSinConexion = false;
  bool alertasVehiculoConductor = true;
  int registrosPendientesSync = 0;

  // ============================================================
  // Parqueadero / celdas
  // ============================================================

  int get cuposDisponibles => zonas.fold(0, (sum, z) => sum + z.disponibles);
  int get cuposTotales => zonas.fold(0, (sum, z) => sum + z.capacidad);

  ParkingZone zonaDe(VehicleType tipo) {
    for (final zona in zonas) {
      if (zona.tipo == tipo) return zona;
    }
    return ParkingZone(etiqueta: tipo.label, tipo: tipo, celdas: const []);
  }

  /// Se llama justo después de iniciar sesión: carga lo necesario para el
  /// rol de la cuenta (el mapa de celdas siempre, y según el rol, el
  /// historial de portería o los vehículos del conductor).
  Future<void> iniciar() async {
    cargando = true;
    notifyListeners();
    try {
      await _cargarParqueaderoYCeldas();
      if (_session.esConductor) {
        await _cargarVehiculosConductor();
        await _cargarCeldaDeMisVehiculos();
      } else if (_session.esVigilanteOAdmin) {
        await _cargarHistorialSemana();
      }
    } catch (_) {
      // Un fallo puntual de red al arrancar no debe dejar la app sin poder
      // abrir: las pantallas simplemente muestran los datos en cero/vacíos
      // hasta que una acción vuelva a intentar cargar.
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void reiniciarCache() {
    _parqueaderoId = null;
    _sede = 'ParkU';
    zonas = const [];
    historial = [];
    _misVehiculos = const [];
    _celdaPorPlaca.clear();
    _vehiculosPorId = {};
  }

  Future<void> _cargarParqueaderoYCeldas() async {
    final parqueaderos = await ApiClient.instance.get('/parqueaderos/');
    if (parqueaderos is List && parqueaderos.isNotEmpty) {
      final primero = parqueaderos.first as Map<String, dynamic>;
      _parqueaderoId = primero['id'] as int?;
      _sede = (primero['nombre'] as String?) ?? _sede;
    }
    if (_parqueaderoId == null) return;

    final celdasJson = await ApiClient.instance.get('/celdas/parqueadero/$_parqueaderoId') as List;

    final carros = <ParkingCell>[];
    final motos = <ParkingCell>[];
    for (final json in celdasJson) {
      final mapa = json as Map<String, dynamic>;
      final celda = ParkingCell.fromJson(mapa);
      if (VehicleTypeLabel.desdeApi(mapa['tipo'] as String?) == VehicleType.moto) {
        motos.add(celda);
      } else {
        carros.add(celda);
      }
    }

    zonas = [
      ParkingZone(etiqueta: 'Carros', tipo: VehicleType.carro, celdas: carros),
      ParkingZone(etiqueta: 'Motos', tipo: VehicleType.moto, celdas: motos),
    ];
  }

  // ============================================================
  // Vehículos
  // ============================================================

  List<Vehicle> misVehiculos() => _misVehiculos;

  Future<void> _cargarVehiculosConductor() async {
    final conductorId = _session.conductorId;
    if (conductorId == null) {
      _misVehiculos = const [];
      return;
    }
    final data = await ApiClient.instance.get('/vehiculos/conductor/$conductorId');
    _misVehiculos = (data as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Busca un vehículo por placa exacta (para el flujo de escaneo/portería).
  /// `GET /vehiculos/buscar` hace autocompletado por prefijo, así que aquí
  /// se filtra la coincidencia exacta entre los resultados.
  Future<Vehicle?> buscarVehiculo(String placa) async {
    final normal = normaliza(placa);
    if (normal.isEmpty) return null;
    final data = await ApiClient.instance.get('/vehiculos/buscar', query: {'placa': normal});
    if (data is! List) return null;
    for (final item in data) {
      final vehiculo = Vehicle.fromJson(item as Map<String, dynamic>);
      if (normaliza(vehiculo.placa) == normal) return _conDocumentoDeConductor(vehiculo);
    }
    return null;
  }

  /// El vehículo solo trae el nombre de su conductor principal
  /// (`conductor_principal_nombre`); su documento y tipo de usuario se
  /// resuelven aparte con `conductor_principal_id`, para que la pantalla de
  /// "vehículo autorizado" pueda mostrar quién es de verdad.
  Future<Vehicle> _conDocumentoDeConductor(Vehicle vehiculo) async {
    if (vehiculo.conductorPrincipalId == null) return vehiculo;
    try {
      final data = await ApiClient.instance.get('/conductores/${vehiculo.conductorPrincipalId}');
      if (data is! Map<String, dynamic>) return vehiculo;
      final tipoDoc = data['tipo_documento'] as String?;
      final numeroDoc = data['numero_documento'] as String?;
      final documento = (tipoDoc != null && numeroDoc != null) ? '$tipoDoc $numeroDoc' : null;
      return vehiculo.copyWith(
        conductorRol: data['tipo_usuario_nombre'] as String?,
        conductorDocumento: documento,
      );
    } catch (_) {
      return vehiculo;
    }
  }

  Future<void> registrarVehiculo({
    required String placa,
    required VehicleType tipo,
    required String marcaLinea,
    required String color,
    required bool soatVigente,
  }) async {
    final partes = marcaLinea.trim().split(RegExp(r'\s+'));
    final marca = partes.isNotEmpty ? partes.first : marcaLinea;
    final linea = partes.length > 1 ? partes.sublist(1).join(' ') : null;

    await ApiClient.instance.post('/vehiculos', body: {
      if (_session.conductorId != null) 'conductor_id': _session.conductorId,
      'placa': normaliza(placa),
      'tipo': tipo.apiValue,
      'marca': marca,
      if (linea != null) 'linea': linea,
      'color': color,
    });

    await _cargarVehiculosConductor();
    await _cargarCeldaDeMisVehiculos();
    notifyListeners();
  }

  /// Para cada vehículo del conductor, revisa si tiene una ocupación activa
  /// (`/ocupaciones/vehiculo/:id`, sin restricción de rol) y, si la tiene,
  /// resuelve la celda para poder mostrarla en el inicio del conductor.
  Future<void> _cargarCeldaDeMisVehiculos() async {
    _celdaPorPlaca.clear();
    for (final vehiculo in _misVehiculos) {
      if (vehiculo.id == null) continue;
      try {
        final ocupaciones = await ApiClient.instance.get('/ocupaciones/vehiculo/${vehiculo.id}');
        if (ocupaciones is! List) continue;
        Map<String, dynamic>? activa;
        for (final o in ocupaciones) {
          final mapa = o as Map<String, dynamic>;
          if (mapa['estado'] == 'ACTIVA' && mapa['fecha_hora_fin'] == null) {
            activa = mapa;
            break;
          }
        }
        if (activa == null) continue;
        final celdaId = activa['celda_id'] as int?;
        if (celdaId == null) continue;
        final celdaJson = await ApiClient.instance.get('/celdas/$celdaId');
        final celda = ParkingCell.fromJson(celdaJson as Map<String, dynamic>);
        celda.estado = CellStatus.ocupada;
        celda.placa = formatea(vehiculo.placa);
        celda.conductorNombre = vehiculo.conductorNombre;
        final inicio = activa['fecha_hora_inicio'] as String?;
        celda.desde = inicio != null ? DateTime.tryParse(inicio) : null;
        _celdaPorPlaca[normaliza(vehiculo.placa)] = celda;
      } catch (_) {
        // Si una ocupación puntual falla, el resto de vehículos se siguen
        // resolviendo: no vale la pena tumbar todo el inicio del conductor
        // por eso.
      }
    }
  }

  ParkingCell? celdaDePlaca(String placa) => _celdaPorPlaca[normaliza(placa)];

  /// Vehículo dentro del parqueadero con esta placa (para registrar salida
  /// desde portería). A diferencia de [celdaDePlaca] (que solo cachea los
  /// vehículos del conductor con sesión activa), esta sí golpea la red: la
  /// usa el guarda para CUALQUIER placa, no solo las propias.
  Future<ParkedVehicle?> buscarDentro(String placa) async {
    final vehiculo = await buscarVehiculo(placa);
    if (vehiculo == null || vehiculo.id == null) return null;

    final ocupaciones = await ApiClient.instance.get('/ocupaciones/vehiculo/${vehiculo.id}');
    if (ocupaciones is! List) return null;
    Map<String, dynamic>? activa;
    for (final o in ocupaciones) {
      final mapa = o as Map<String, dynamic>;
      if (mapa['estado'] == 'ACTIVA' && mapa['fecha_hora_fin'] == null) {
        activa = mapa;
        break;
      }
    }
    if (activa == null) return null;

    final celdaId = activa['celda_id'] as int?;
    String celdaCodigo = '—';
    if (celdaId != null) {
      try {
        final celdaJson = await ApiClient.instance.get('/celdas/$celdaId');
        celdaCodigo = (celdaJson as Map<String, dynamic>)['numero']?.toString() ?? celdaCodigo;
      } catch (_) {}
    }
    final inicio = activa['fecha_hora_inicio'] as String?;
    return ParkedVehicle(
      placa: formatea(vehiculo.placa),
      conductorNombre: vehiculo.conductorNombre,
      celda: celdaCodigo,
      horaIngreso: (inicio != null ? DateTime.tryParse(inicio) : null) ?? DateTime.now(),
    );
  }

  // ============================================================
  // Ingresos / salidas
  // ============================================================

  Future<String> registrarIngreso(Vehicle vehicle, {ParkingCell? celda}) async {
    if (_parqueaderoId == null) {
      throw const ApiException('No se pudo determinar el parqueadero. Vuelve a intentarlo.');
    }
    var destino = celda;
    destino ??= zonaDe(vehicle.tipo).celdas.where((c) => c.esLibre).firstOrNull;

    await ApiClient.instance.post('/entradas-salidas/entrada', body: {
      'vehiculo_id': vehicle.id,
      'parqueadero_id': _parqueaderoId,
      if (destino?.id != null) 'celda_id': destino!.id,
    });

    final placaFormateada = formatea(vehicle.placa);
    if (destino != null) {
      destino.estado = CellStatus.ocupada;
      destino.placa = placaFormateada;
      destino.conductorNombre = vehicle.conductorNombre;
      destino.desde = DateTime.now();
    }

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Celda ${destino?.codigo ?? '—'} · ${vehicle.conductorNombre}',
        hora: DateTime.now(),
        estado: AccessStatus.dentro,
      ),
    );
    notifyListeners();
    return destino?.codigo ?? '—';
  }

  Future<void> registrarSalida(String placa) async {
    final vehiculo = await buscarVehiculo(placa);
    if (vehiculo == null || vehiculo.id == null) {
      throw const ApiException('No se encontró un vehículo registrado con esa placa.');
    }

    await ApiClient.instance.post('/entradas-salidas/salida', body: {'vehiculo_id': vehiculo.id});

    final placaFormateada = formatea(vehiculo.placa);
    final celda = _celdaEnCache(placaFormateada);
    final permanencia = celda?.permanencia != null ? formatDuration(celda!.permanencia!) : '--';
    final conductor = celda?.conductorNombre ?? vehiculo.conductorNombre;

    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Salida · $permanencia · $conductor',
        hora: DateTime.now(),
        estado: AccessStatus.salio,
      ),
    );

    if (celda != null) {
      celda.estado = CellStatus.libre;
      celda.placa = null;
      celda.conductorNombre = null;
      celda.desde = null;
    }
    notifyListeners();
  }

  ParkingCell? _celdaEnCache(String placaFormateada) {
    for (final zona in zonas) {
      for (final celda in zona.celdas) {
        if (celda.esOcupada && celda.placa != null && normaliza(celda.placa!) == normaliza(placaFormateada)) {
          return celda;
        }
      }
    }
    return _celdaPorPlaca[normaliza(placaFormateada)];
  }

  /// Api-ParkU no tiene un concepto de "visitante": se documenta como una
  /// novedad (incidente tipo OTRO) para que quede registro, ya que no hay
  /// vehículo/conductor al que asociar un ingreso real. `parqueadero_id` y
  /// `tipo_otro` son obligatorios para este tipo (ver novedades.service.js).
  Future<void> registrarVisitante(String placa) async {
    final placaFormateada = formatea(placa);
    await ApiClient.instance.post('/novedades', body: {
      'descripcion': 'Placa $placaFormateada — ingreso registrado como visitante en portería.',
      'tipo_novedad': 'OTRO',
      'tipo_otro': 'Visitante',
      'prioridad': 'BAJA',
      if (_parqueaderoId != null) 'parqueadero_id': _parqueaderoId,
    });
    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Ingreso · Visitante',
        hora: DateTime.now(),
        estado: AccessStatus.dentro,
      ),
    );
    notifyListeners();
  }

  Future<void> registrarDenegado(String placa) async {
    final placaFormateada = formatea(placa);
    await ApiClient.instance.post('/novedades', body: {
      'descripcion': 'Placa $placaFormateada — ingreso denegado: sin registro en el sistema.',
      'tipo_novedad': 'OTRO',
      'tipo_otro': 'Ingreso denegado',
      'prioridad': 'MEDIA',
      if (_parqueaderoId != null) 'parqueadero_id': _parqueaderoId,
    });
    historial.insert(
      0,
      AccessRecord(
        placa: placaFormateada,
        detalle: 'Denegado · sin registro',
        hora: DateTime.now(),
        estado: AccessStatus.novedad,
      ),
    );
    notifyListeners();
  }

  // ============================================================
  // Novedades / incidentes / quejas
  // ============================================================

  /// POST /novedades — cualquier usuario autenticado (conductor, vigilante o
  /// administrador) puede reportar una novedad. Se usa tanto desde portería
  /// (celda, vehículo escaneado) como desde el conductor (queja o incidente
  /// sobre su propio vehículo), por eso las referencias son opcionales.
  Future<void> reportarNovedad({
    required String tipoNovedad,
    required String descripcion,
    String prioridad = 'MEDIA',
    int? vehiculoId,
    int? celdaId,
  }) async {
    await ApiClient.instance.post('/novedades', body: {
      'tipo_novedad': tipoNovedad,
      'prioridad': prioridad,
      'descripcion': descripcion,
      if (vehiculoId != null) 'vehiculo_id': vehiculoId,
      if (celdaId != null) 'celda_id': celdaId,
      if (_parqueaderoId != null) 'parqueadero_id': _parqueaderoId,
    });
  }

  // ============================================================
  // Historial (portería)
  // ============================================================

  /// Cachea la última semana de ingresos/salidas (`/entradas-salidas/filtro`)
  /// más las novedades recientes, para que [historialFiltrado] siga
  /// filtrando en memoria como antes. Solo disponible para vigilante/admin:
  /// la API no deja consultar esto con rol Conductor.
  Future<void> _cargarHistorialSemana() async {
    final hoy = DateTime.now();
    final hace7 = hoy.subtract(const Duration(days: 7));
    final desde = _formatoFecha(hace7);
    final hasta = _formatoFecha(hoy);

    final vehiculosJson = await ApiClient.instance.get('/vehiculos/') as List;
    _vehiculosPorId = {
      for (final item in vehiculosJson)
        (item as Map<String, dynamic>)['id'] as int: Vehicle.fromJson(item),
    };

    final registros = <AccessRecord>[];

    try {
      final data = await ApiClient.instance.get('/entradas-salidas/filtro', query: {'desde': desde, 'hasta': hasta});
      if (data is List) {
        for (final item in data) {
          final registro = item as Map<String, dynamic>;
          registros.add(_accessRecordDeRegistro(registro));
        }
      }
    } catch (_) {
      // Sin permiso o sin datos: se sigue con lo que haya de novedades.
    }

    try {
      final novedades = await ApiClient.instance.get('/novedades');
      if (novedades is List) {
        for (final item in novedades) {
          final novedad = item as Map<String, dynamic>;
          final fecha = DateTime.tryParse(novedad['fecha_hora']?.toString() ?? '');
          if (fecha == null || fecha.isBefore(hace7)) continue;
          registros.add(_accessRecordDeNovedad(novedad, fecha));
        }
      }
    } catch (_) {}

    registros.sort((a, b) => b.hora.compareTo(a.hora));
    historial = registros;
  }

  AccessRecord _accessRecordDeRegistro(Map<String, dynamic> registro) {
    final vehiculo = _vehiculosPorId[registro['vehiculo_id'] as int?];
    final placa = vehiculo != null ? formatea(vehiculo.placa) : '—';
    final conductor = vehiculo?.conductorNombre ?? '—';
    final ingreso = DateTime.tryParse(registro['fecha_hora_ingreso']?.toString() ?? '');
    final salidaTexto = registro['fecha_hora_salida']?.toString();
    final salida = salidaTexto != null ? DateTime.tryParse(salidaTexto) : null;

    if (salida == null) {
      return AccessRecord(
        placa: placa,
        detalle: 'Ingreso · $conductor',
        hora: ingreso ?? DateTime.now(),
        estado: registro['estado'] == 'BLOQUEADO' ? AccessStatus.novedad : AccessStatus.dentro,
      );
    }
    final duracion = ingreso != null ? formatDuration(salida.difference(ingreso)) : '--';
    return AccessRecord(
      placa: placa,
      detalle: 'Salida · $duracion · $conductor',
      hora: salida,
      estado: AccessStatus.salio,
    );
  }

  AccessRecord _accessRecordDeNovedad(Map<String, dynamic> novedad, DateTime fecha) {
    final descripcion = (novedad['descripcion'] as String?) ?? 'Novedad';
    final coincidencia = RegExp(r'^Placa (\S+)').firstMatch(descripcion);
    final placa = coincidencia != null ? formatea(coincidencia.group(1)!) : '—';
    return AccessRecord(placa: placa, detalle: descripcion, hora: fecha, estado: AccessStatus.novedad);
  }

  String _formatoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<AccessRecord> historialFiltrado(String filtro) => _filtrarPorFecha(historial, filtro);

  /// La API no deja que un Conductor consulte entradas/salidas (solo
  /// vigilante/admin): para ese rol el historial local queda vacío.
  List<AccessRecord> historialDeConductor() {
    final placas = _misVehiculos.map((v) => normaliza(v.placa)).toSet();
    return historial.where((r) => placas.contains(normaliza(r.placa))).toList();
  }

  List<AccessRecord> historialDeConductorFiltrado(String filtro) => _filtrarPorFecha(historialDeConductor(), filtro);

  List<AccessRecord> _filtrarPorFecha(List<AccessRecord> registros, String filtro) {
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
    switch (filtro) {
      case 'Ayer':
        final ayerInicio = hoyInicio.subtract(const Duration(days: 1));
        return registros.where((r) => r.hora.isAfter(ayerInicio) && r.hora.isBefore(hoyInicio)).toList();
      case '7 días':
        final hace7 = ahora.subtract(const Duration(days: 7));
        return registros.where((r) => r.hora.isAfter(hace7)).toList();
      case 'Hoy':
      default:
        return registros.where((r) => r.hora.isAfter(hoyInicio)).toList();
    }
  }

  // ============================================================
  // Preferencias locales / utilidades
  // ============================================================

  void actualizarAlertas(bool valor) {
    alertasNoAutorizados = valor;
    notifyListeners();
  }

  void actualizarModoSinConexion(bool valor) {
    modoSinConexion = valor;
    notifyListeners();
  }

  void actualizarAlertasVehiculoConductor(bool valor) {
    alertasVehiculoConductor = valor;
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

  static String normaliza(String placa) => placa.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String formatea(String placaNormalizada) {
    final limpia = normaliza(placaNormalizada);
    if (limpia.length <= 3) return limpia;
    return '${limpia.substring(0, 3)} ${limpia.substring(3)}';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

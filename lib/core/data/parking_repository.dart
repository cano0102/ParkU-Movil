import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../models/access_record.dart';
import '../models/asignacion_vigilante.dart';
import '../models/notificacion.dart';
import '../models/parking_cell.dart';
import '../models/parking_zone.dart';
import '../models/parqueadero.dart';
import '../models/reserva.dart';
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

  /// Parqueaderos activos de la sede. El mapa muestra las celdas de todos
  /// (agrupadas por tipo de vehículo) y las reservas piden elegir uno.
  List<Parqueadero> parqueaderos = const [];

  /// Parqueadero por defecto para lo que no está ligado a una celda concreta
  /// (novedades de portería): el primero de la lista.
  int? _parqueaderoId;
  String _sede = 'ParkU';

  List<ParkingZone> zonas = const [];
  List<AccessRecord> historial = [];
  List<Vehicle> _misVehiculos = const [];

  /// Reservas de los vehículos del conductor con sesión activa (todas, de
  /// más reciente a más antigua). Vacío para vigilante/admin.
  List<Reserva> reservas = const [];

  /// Notificaciones del usuario con sesión (`GET /notificaciones`), más
  /// recientes primero. La campana muestra cuántas siguen sin leer.
  List<Notificacion> notificaciones = const [];
  int get notificacionesNoLeidas => notificaciones.where((n) => !n.leida).length;

  /// Celda actual (si la hay) de cada placa normalizada del conductor con
  /// sesión activa. Api-ParkU no incluye el ocupante en `/celdas`, así que
  /// esto se resuelve aparte (ver [_cargarOcupacionesDeMisVehiculos]) y se
  /// cachea para que `celdaDePlaca` siga siendo síncrono, como usan las
  /// pantallas.
  final Map<String, ParkingCell> _celdaPorPlaca = {};

  bool cargando = false;

  // ============================================================
  // Datos de sesión (antes fijos, ahora vienen de SessionRepository)
  // ============================================================

  String get sede => _sede;
  String get guardaNombre => _session.nombre ?? '—';
  String get guardaCorreo => _session.correo ?? '—';
  String get guardaRol => _session.rolNombre ?? 'Vigilante';

  /// Turno vigente del vigilante (`/asignaciones-vigilante/usuario/:id`):
  /// de aquí salen la "portería" (su parqueadero) y el turno que se muestran,
  /// y el parqueadero al que se cargan las novedades sin celda.
  AsignacionVigilante? asignacion;

  String get porteria => asignacion?.parqueaderoNombre ?? 'Sin asignar';
  String get turno => asignacion?.turnoConHoras ?? 'Sin turno asignado';
  int? get parqueaderoAsignadoId => asignacion?.parqueaderoId;

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
      await _cargarTodo();
    } catch (_) {
      // Un fallo puntual de red al arrancar no debe dejar la app sin poder
      // abrir: las pantallas simplemente muestran los datos en cero/vacíos
      // hasta que una acción vuelva a intentar cargar.
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Vuelve a pedir todo a la API (tirar para refrescar). A diferencia de
  /// [iniciar], propaga el error para que la pantalla pueda avisarlo.
  Future<void> recargar() async {
    cargando = true;
    notifyListeners();
    try {
      await _cargarTodo();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  /// Solo el historial (más barato que [recargar]): para el conductor, sus
  /// estadías; para portería, la semana de ingresos/salidas y novedades. Se
  /// usa al abrir la pestaña Historial y al tirar para refrescar, para que
  /// una salida registrada en portería aparezca sin reiniciar la app.
  Future<void> recargarHistorial() async {
    if (_session.esConductor) {
      await _cargarOcupacionesDeMisVehiculos();
    } else if (_session.esVigilanteOAdmin) {
      await _cargarHistorialSemana();
    }
    notifyListeners();
  }

  Future<void> _cargarTodo() async {
    await _cargarParqueaderosYCeldas();
    await _cargarNotificaciones();
    if (_session.esConductor) {
      await _cargarVehiculosConductor();
      await _cargarOcupacionesDeMisVehiculos();
      await _cargarMisReservas();
    } else if (_session.esVigilanteOAdmin) {
      await _cargarAsignacionVigilante();
      await _cargarHistorialSemana();
    }
  }

  void reiniciarCache() {
    parqueaderos = const [];
    asignacion = null;
    _parqueaderoId = null;
    _sede = 'ParkU';
    zonas = const [];
    historial = [];
    _misVehiculos = const [];
    reservas = const [];
    notificaciones = const [];
    _celdaPorPlaca.clear();
  }

  // ============================================================
  // Notificaciones
  // ============================================================

  Future<void> _cargarNotificaciones() async {
    try {
      final data = await ApiClient.instance.get('/notificaciones');
      notificaciones = data is List ? data.map((e) => Notificacion.fromJson(e as Map<String, dynamic>)).toList() : const [];
    } catch (_) {
      // Sin notificaciones no pasa nada: la campana simplemente queda en cero.
    }
  }

  Future<void> recargarNotificaciones() async {
    await _cargarNotificaciones();
    notifyListeners();
  }

  /// PATCH /notificaciones/:id/leida — se marca localmente de una vez para
  /// que la campana baje sin esperar la respuesta.
  Future<void> marcarNotificacionLeida(Notificacion n) async {
    if (n.leida) return;
    n.leida = true;
    notifyListeners();
    try {
      await ApiClient.instance.patch('/notificaciones/${n.id}/leida');
    } catch (_) {
      n.leida = false;
      notifyListeners();
      rethrow;
    }
  }

  /// PATCH /notificaciones/leer-todas.
  Future<void> marcarTodasNotificacionesLeidas() async {
    if (notificacionesNoLeidas == 0) return;
    await ApiClient.instance.patch('/notificaciones/leer-todas');
    for (final n in notificaciones) {
      n.leida = true;
    }
    notifyListeners();
  }

  /// Carga los parqueaderos activos y TODAS sus celdas. Para vigilante/admin
  /// usa `/monitoreo/celdas`, que trae de una vez quién ocupa cada celda y
  /// desde cuándo; un conductor no tiene acceso a eso y recibe solo el
  /// estado de cada celda desde `/celdas`.
  Future<void> _cargarParqueaderosYCeldas() async {
    final parqueaderosJson = await ApiClient.instance.get('/parqueaderos/');
    parqueaderos = parqueaderosJson is List
        ? parqueaderosJson.map((e) => Parqueadero.fromJson(e as Map<String, dynamic>)).where((p) => p.activo).toList()
        : const [];
    _parqueaderoId = parqueaderos.isEmpty ? null : parqueaderos.first.id;
    _sede = switch (parqueaderos.length) {
      0 => 'ParkU',
      1 => parqueaderos.first.nombre,
      final n => 'SENA · $n parqueaderos',
    };
    if (parqueaderos.isEmpty) {
      zonas = const [];
      return;
    }

    List celdasJson;
    if (_session.esVigilanteOAdmin) {
      try {
        celdasJson = await ApiClient.instance.get('/monitoreo/celdas') as List;
      } on ApiException catch (e) {
        // Un rol a medida sin `reportes.consultar` cae al listado plano.
        if (!e.esProhibido) rethrow;
        celdasJson = await ApiClient.instance.get('/celdas/') as List;
      }
    } else {
      celdasJson = await ApiClient.instance.get('/celdas/') as List;
    }

    final activos = {for (final p in parqueaderos) p.id: p.nombre};
    final carros = <ParkingCell>[];
    final motos = <ParkingCell>[];
    for (final json in celdasJson) {
      final mapa = json as Map<String, dynamic>;
      final celda = ParkingCell.fromJson(mapa);
      // La placa del ocupante llega "KEC35F"; la app la muestra "KEC 35F".
      if (celda.placa != null) celda.placa = formatea(celda.placa!);
      // Celdas de parqueaderos inactivos no se pueden usar: no se muestran.
      if (celda.parqueaderoId != null && !activos.containsKey(celda.parqueaderoId)) continue;
      // La API admite BICICLETA/CAMION/BUS como tipos históricos de celda,
      // pero solo registra vehículos CARRO|MOTO: esas celdas no aplican aquí.
      final tipoApi = (mapa['tipo'] as String?)?.toUpperCase();
      if (tipoApi == 'MOTO') {
        motos.add(celda);
      } else if (tipoApi == 'CARRO' || tipoApi == null) {
        carros.add(celda);
      }
    }

    zonas = [
      ParkingZone(etiqueta: 'Carros', tipo: VehicleType.carro, celdas: carros),
      ParkingZone(etiqueta: 'Motos', tipo: VehicleType.moto, celdas: motos),
    ];
  }

  Parqueadero? parqueaderoPorId(int? id) {
    for (final p in parqueaderos) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Turno del vigilante con sesión. Si tiene varios vigentes (p. ej. mañana
  /// y tarde), se queda con el que cubre la hora actual; si ninguno la
  /// cubre, el más reciente. Un administrador normalmente no tiene ninguno
  /// y queda "Sin asignar".
  Future<void> _cargarAsignacionVigilante() async {
    asignacion = null;
    final usuarioId = _session.usuarioId;
    if (usuarioId == null) return;
    try {
      final data = await ApiClient.instance.get('/asignaciones-vigilante/usuario/$usuarioId');
      if (data is! List) return;
      final ahora = DateTime.now();
      final vigentes = data.map((e) => AsignacionVigilante.fromJson(e as Map<String, dynamic>)).where((a) => a.vigenteEn(ahora)).toList();
      if (vigentes.isEmpty) return;
      asignacion = vigentes.where((a) => a.cubreHora(ahora)).firstOrNull ?? vigentes.first;
    } catch (_) {
      // Sin asignación (o sin permiso) el guarda sigue pudiendo operar: las
      // novedades caen al parqueadero por defecto.
    }
  }

  /// Parqueadero al que se carga una novedad: el de la celda si la hay
  /// (`/novedades` también lo deduce solo de `celda_id`), si no el del turno
  /// del vigilante, y en último caso el primero de la lista.
  int? _parqueaderoParaNovedad({int? celdaId}) {
    if (celdaId != null) {
      for (final zona in zonas) {
        for (final celda in zona.celdas) {
          if (celda.id == celdaId && celda.parqueaderoId != null) return celda.parqueaderoId;
        }
      }
    }
    return parqueaderoAsignadoId ?? _parqueaderoId;
  }

  /// Marca en el mapa qué celdas puede ocupar [vehicle] ahora mismo según
  /// `/celdas/parqueadero/:id/disponibles?vehiculo_id=`: la API descarta las
  /// que retiene una reserva ajena (ahora o en menos de dos horas) y señala
  /// la reservada para este vehículo, que la app preselecciona. Sin esto la
  /// app ofrecía cualquier celda DISPONIBLE y el ingreso fallaba con 409.
  ///
  /// Devuelve la celda reservada para el vehículo, si la hay.
  Future<ParkingCell?> marcarAsignablesPara(Vehicle vehicle) async {
    if (vehicle.id == null) return null;
    final ofrecidas = <int, bool>{};
    for (final parqueadero in parqueaderos) {
      try {
        final data = await ApiClient.instance.get('/celdas/parqueadero/${parqueadero.id}/disponibles', query: {'vehiculo_id': vehicle.id});
        if (data is! List) continue;
        for (final item in data) {
          final mapa = item as Map<String, dynamic>;
          final id = mapa['id'] as int?;
          if (id != null) ofrecidas[id] = mapa['reservada_para_este_vehiculo'] == true;
        }
      } catch (_) {
        // Si un parqueadero falla, sus celdas quedan como "retenidas" (no
        // se ofrecen): mejor no ofrecer que ofrecer y fallar al confirmar.
      }
    }

    ParkingCell? reservada;
    for (final celda in zonaDe(vehicle.tipo).celdas) {
      final id = celda.id;
      final ofrecida = id != null && ofrecidas.containsKey(id);
      celda.reservadaParaVehiculo = ofrecida && ofrecidas[id] == true;
      celda.retenidaPorReserva = celda.esLibre && !ofrecida;
      if (celda.reservadaParaVehiculo) reservada = celda;
    }
    notifyListeners();
    return reservada;
  }

  /// Deshace [marcarAsignablesPara] al salir del selector de celda.
  void limpiarAsignables() {
    for (final zona in zonas) {
      for (final celda in zona.celdas) {
        celda.reservadaParaVehiculo = false;
        celda.retenidaPorReserva = false;
      }
    }
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
      return vehiculo.copyWith(conductorRol: data['tipo_usuario_nombre'] as String?, conductorDocumento: documento);
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

    await ApiClient.instance.post(
      '/vehiculos',
      body: {
        if (_session.conductorId != null) 'conductor_id': _session.conductorId,
        'placa': normaliza(placa),
        'tipo': tipo.apiValue,
        'marca': marca,
        'linea': ?linea,
        'color': color,
      },
    );

    await _cargarVehiculosConductor();
    await _cargarOcupacionesDeMisVehiculos();
    await _cargarMisReservas();
    notifyListeners();
  }

  /// Estadías de los vehículos del conductor (`/ocupaciones/vehiculo/:id`,
  /// lo único de ingresos/salidas que la API deja ver a un Conductor). De
  /// aquí salen dos cosas: la celda que ocupa ahora cada vehículo (para el
  /// inicio y la lista de vehículos) y su historial de ingresos y salidas,
  /// con celda, hora de entrada y hora de salida.
  Future<void> _cargarOcupacionesDeMisVehiculos() async {
    _celdaPorPlaca.clear();
    final registros = <AccessRecord>[];
    for (final vehiculo in _misVehiculos) {
      if (vehiculo.id == null) continue;
      try {
        final ocupaciones = await ApiClient.instance.get('/ocupaciones/vehiculo/${vehiculo.id}');
        if (ocupaciones is! List) continue;
        for (final o in ocupaciones) {
          final mapa = o as Map<String, dynamic>;
          final inicio = DateTime.tryParse(mapa['fecha_hora_inicio']?.toString() ?? '')?.toLocal();
          if (inicio == null) continue;
          final fin = DateTime.tryParse(mapa['fecha_hora_fin']?.toString() ?? '')?.toLocal();
          final celdaJson = mapa['celda'];
          final celdaId = (mapa['celda_id'] ?? (celdaJson is Map ? celdaJson['id'] : null)) as int?;
          final celdaNumero = celdaJson is Map ? celdaJson['numero']?.toString() : null;
          final parqueaderoId = celdaJson is Map ? celdaJson['parqueadero'] as int? : null;
          final parqueaderoNombre = parqueaderoPorId(parqueaderoId)?.nombre ?? _celdaPorId(celdaId)?.parqueaderoNombre;
          final estado = (mapa['estado'] as String?)?.toUpperCase();

          // CANCELADA: la estadía no llegó a ocurrir (p. ej. ingreso anulado).
          if (estado == 'CANCELADA') continue;
          registros.add(
            AccessRecord.estadia(
              placa: formatea(vehiculo.placa),
              ingreso: inicio,
              salida: fin,
              celda: celdaNumero ?? _celdaPorId(celdaId)?.codigo,
              parqueadero: parqueaderoNombre,
            ),
          );

          if (estado == 'ACTIVA' && fin == null && celdaId != null && !_celdaPorPlaca.containsKey(normaliza(vehiculo.placa))) {
            final celda = _celdaPorId(celdaId) ?? await _celdaDesdeApi(celdaId);
            if (celda == null) continue;
            celda.estado = CellStatus.ocupada;
            celda.placa = formatea(vehiculo.placa);
            celda.conductorNombre = vehiculo.conductorNombre;
            celda.desde = inicio;
            _celdaPorPlaca[normaliza(vehiculo.placa)] = celda;
          }
        }
      } catch (_) {
        // Si una ocupación puntual falla, el resto de vehículos se siguen
        // resolviendo: no vale la pena tumbar todo el inicio del conductor
        // por eso.
      }
    }
    registros.sort((a, b) => b.hora.compareTo(a.hora));
    historial = registros;
  }

  ParkingCell? _celdaPorId(int? id) {
    if (id == null) return null;
    for (final zona in zonas) {
      for (final celda in zona.celdas) {
        if (celda.id == id) return celda;
      }
    }
    return null;
  }

  /// Celda que no está en el mapa cacheado (p. ej. de un tipo que la app no
  /// muestra): se pide aparte solo para poder mostrar dónde está el vehículo.
  Future<ParkingCell?> _celdaDesdeApi(int celdaId) async {
    try {
      final json = await ApiClient.instance.get('/celdas/$celdaId');
      return json is Map<String, dynamic> ? ParkingCell.fromJson(json) : null;
    } catch (_) {
      return null;
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
    var destino = celda;
    destino ??= zonaDe(vehicle.tipo).celdas.where((c) => c.esAsignable).firstOrNull;

    // El ingreso se registra en el parqueadero de la celda elegida; sin celda
    // (no quedaba ninguna libre) va al parqueadero por defecto.
    final parqueaderoId = destino?.parqueaderoId ?? _parqueaderoId;
    if (parqueaderoId == null) {
      throw const ApiException('No se pudo determinar el parqueadero. Vuelve a intentarlo.');
    }

    await ApiClient.instance.post(
      '/entradas-salidas/entrada',
      body: {'vehiculo_id': vehicle.id, 'parqueadero_id': parqueaderoId, if (destino?.id != null) 'celda_id': destino!.id},
    );

    final placaFormateada = formatea(vehicle.placa);
    if (destino != null) {
      destino.estado = CellStatus.ocupada;
      destino.placa = placaFormateada;
      destino.conductorNombre = vehicle.conductorNombre;
      destino.desde = DateTime.now();
    }

    historial.insert(
      0,
      AccessRecord.estadia(
        placa: placaFormateada,
        ingreso: DateTime.now(),
        celda: destino?.codigo,
        parqueadero: destino?.parqueaderoNombre ?? parqueaderoPorId(parqueaderoId)?.nombre,
        conductor: vehicle.conductorNombre,
      ),
    );
    notifyListeners();
    return destino?.codigoConParqueadero ?? '—';
  }

  Future<void> registrarSalida(String placa) async {
    final vehiculo = await buscarVehiculo(placa);
    if (vehiculo == null || vehiculo.id == null) {
      throw const ApiException('No se encontró un vehículo registrado con esa placa.');
    }

    await ApiClient.instance.post('/entradas-salidas/salida', body: {'vehiculo_id': vehiculo.id});

    final placaFormateada = formatea(vehiculo.placa);
    final celda = _celdaEnCache(placaFormateada);
    final conductor = celda?.conductorNombre ?? vehiculo.conductorNombre;
    final salida = DateTime.now();

    // La estadía abierta de esta placa (si está en el historial cargado) se
    // reemplaza por la cerrada, para que quede una sola fila con las dos
    // horas, igual que cuando la manda la API.
    final indiceAbierta = historial.indexWhere((r) => r.estado == AccessStatus.dentro && normaliza(r.placa) == normaliza(placaFormateada));
    final abierta = indiceAbierta >= 0 ? historial.removeAt(indiceAbierta) : null;
    historial.insert(
      0,
      AccessRecord.estadia(
        placa: placaFormateada,
        ingreso: abierta?.ingreso ?? celda?.desde ?? salida,
        salida: salida,
        celda: abierta?.celda ?? celda?.codigo,
        parqueadero: abierta?.parqueadero ?? celda?.parqueaderoNombre,
        conductor: abierta?.conductor ?? conductor,
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
    await ApiClient.instance.post(
      '/novedades',
      body: {
        'descripcion': 'Placa $placaFormateada — ingreso registrado como visitante en portería.',
        'tipo_novedad': 'OTRO',
        'tipo_otro': 'Visitante',
        'prioridad': 'BAJA',
        'parqueadero_id': ?_parqueaderoParaNovedad(),
      },
    );
    historial.insert(
      0,
      AccessRecord(placa: placaFormateada, detalle: 'Ingreso · Visitante', hora: DateTime.now(), estado: AccessStatus.dentro),
    );
    notifyListeners();
  }

  Future<void> registrarDenegado(String placa) async {
    final placaFormateada = formatea(placa);
    await ApiClient.instance.post(
      '/novedades',
      body: {
        'descripcion': 'Placa $placaFormateada — ingreso denegado: sin registro en el sistema.',
        'tipo_novedad': 'OTRO',
        'tipo_otro': 'Ingreso denegado',
        'prioridad': 'MEDIA',
        'parqueadero_id': ?_parqueaderoParaNovedad(),
      },
    );
    historial.insert(
      0,
      AccessRecord(placa: placaFormateada, detalle: 'Denegado · sin registro', hora: DateTime.now(), estado: AccessStatus.novedad),
    );
    notifyListeners();
  }

  // ============================================================
  // Reservas (conductor)
  // ============================================================

  /// `GET /reservas` está restringido a vigilante/admin; un conductor solo
  /// puede pedir las de cada vehículo suyo (`/reservas/vehiculo/:id`), así
  /// que se juntan aquí.
  Future<void> _cargarMisReservas() async {
    final lista = <Reserva>[];
    for (final vehiculo in _misVehiculos) {
      if (vehiculo.id == null) continue;
      try {
        final data = await ApiClient.instance.get('/reservas/vehiculo/${vehiculo.id}');
        if (data is List) {
          lista.addAll(data.map((e) => Reserva.fromJson(e as Map<String, dynamic>)));
        }
      } catch (_) {
        // Un vehículo sin reservas (o con un error puntual) no debe ocultar
        // las de los demás.
      }
    }
    lista.sort((a, b) => b.inicio.compareTo(a.inicio));
    reservas = lista;
  }

  Future<void> recargarMisReservas() async {
    await _cargarMisReservas();
    notifyListeners();
  }

  /// Celdas DISPONIBLES de un parqueadero compatibles con el tipo de
  /// vehículo (`?tipo=CARRO|MOTO`), para elegir cuál reservar.
  Future<List<ParkingCell>> celdasDisponibles({required int parqueaderoId, required VehicleType tipo}) async {
    final data = await ApiClient.instance.get('/celdas/parqueadero/$parqueaderoId/disponibles', query: {'tipo': tipo.apiValue});
    if (data is! List) return const [];
    return data.map((e) => ParkingCell.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /reservas. La reserva de un conductor nace PENDIENTE hasta que
  /// portería/administración la acepte. `tipo_reserva` es el mismo que usa
  /// el frontend web para una solicitud normal de conductor; la API valida
  /// horario de operación, anticipación mínima y solapamientos, y sus
  /// mensajes se muestran tal cual.
  Future<Reserva> crearReserva({
    required Vehicle vehiculo,
    required ParkingCell celda,
    required DateTime inicio,
    required DateTime fin,
    required String motivo,
  }) async {
    final data = await ApiClient.instance.post(
      '/reservas',
      body: {
        'tipo_reserva': 'VEHICULO_SENA',
        'celda_id': celda.id,
        'vehiculo_id': vehiculo.id,
        'conductor_id': ?_session.conductorId,
        'motivo': motivo.trim(),
        'fecha_hora_inicio': inicio.toUtc().toIso8601String(),
        'fecha_hora_fin': fin.toUtc().toIso8601String(),
      },
    );
    await _cargarMisReservas();
    notifyListeners();
    return Reserva.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /reservas/:id/cancelar — solo las propias y hasta 30 min antes
  /// del inicio (la API devuelve el motivo si no se puede).
  Future<void> cancelarReserva(Reserva reserva, {String? motivo}) async {
    await ApiClient.instance.patch(
      '/reservas/${reserva.id}/cancelar',
      body: {if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim()},
    );
    await _cargarMisReservas();
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
    await ApiClient.instance.post(
      '/novedades',
      body: {
        'tipo_novedad': tipoNovedad,
        'prioridad': prioridad,
        'descripcion': descripcion,
        'vehiculo_id': ?vehiculoId,
        'celda_id': ?celdaId,
        'parqueadero_id': ?_parqueaderoParaNovedad(celdaId: celdaId),
      },
    );
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
    final hace7 = DateTime(hoy.year, hoy.month, hoy.day).subtract(const Duration(days: 7));
    // La API hace `fecha_hora_ingreso BETWEEN desde AND hasta`: si `hasta`
    // fuera la fecha de hoy a secas, sería la medianoche de esta madrugada y
    // los ingresos de hoy quedarían fuera. Se manda el instante completo,
    // hasta mañana, en UTC (como guarda las fechas la base).
    final desde = hace7.toUtc().toIso8601String();
    final hasta = hoy.add(const Duration(days: 1)).toUtc().toIso8601String();

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

  /// Un `registro_acceso` de la API trae anidados `vehiculo {placa}`,
  /// `conductor {nombre_apellidos}`, `parqueadero {nombre}` y `celda
  /// {numero}`: con eso se arma la fila sin más consultas.
  AccessRecord _accessRecordDeRegistro(Map<String, dynamic> registro) {
    final vehiculo = registro['vehiculo'];
    final conductor = registro['conductor'];
    final parqueadero = registro['parqueadero'];
    final celda = registro['celda'];

    final placaCruda = vehiculo is Map ? vehiculo['placa']?.toString() : null;
    final ingreso = DateTime.tryParse(registro['fecha_hora_ingreso']?.toString() ?? '')?.toLocal();
    final salida = DateTime.tryParse(registro['fecha_hora_salida']?.toString() ?? '')?.toLocal();

    return AccessRecord.estadia(
      placa: placaCruda != null ? formatea(placaCruda) : '—',
      ingreso: ingreso ?? DateTime.now(),
      salida: salida,
      celda: celda is Map ? celda['numero']?.toString() : _celdaPorId(registro['celda_id'] as int?)?.codigo,
      parqueadero: parqueadero is Map ? parqueadero['nombre']?.toString() : parqueaderoPorId(registro['parqueadero_id'] as int?)?.nombre,
      conductor: conductor is Map ? conductor['nombre_apellidos']?.toString() : null,
      bloqueado: registro['estado'] == 'BLOQUEADO',
    );
  }

  AccessRecord _accessRecordDeNovedad(Map<String, dynamic> novedad, DateTime fecha) {
    final descripcion = (novedad['descripcion'] as String?) ?? 'Novedad';
    final coincidencia = RegExp(r'^Placa (\S+)').firstMatch(descripcion);
    final placa = coincidencia != null ? formatea(coincidencia.group(1)!) : '—';
    return AccessRecord(placa: placa, detalle: descripcion, hora: fecha, estado: AccessStatus.novedad);
  }

  List<AccessRecord> historialFiltrado(String filtro) => _filtrarPorFecha(historial, filtro);

  /// Para un Conductor el historial ya viene solo de sus vehículos
  /// (ver [_cargarOcupacionesDeMisVehiculos]); el filtro por placa es por
  /// si la cuenta cambia de vehículos sin recargar.
  List<AccessRecord> historialDeConductor() {
    final placas = _misVehiculos.map((v) => normaliza(v.placa)).toSet();
    return historial.where((r) => placas.contains(normaliza(r.placa))).toList();
  }

  List<AccessRecord> historialDeConductorFiltrado(String filtro) => _filtrarPorFecha(historialDeConductor(), filtro);

  /// Una estadía cuenta en un periodo si su ingreso O su salida caen en él:
  /// quien entró ayer y salió hoy debe verse tanto en "Ayer" como en "Hoy".
  List<AccessRecord> _filtrarPorFecha(List<AccessRecord> registros, String filtro) {
    final ahora = DateTime.now();
    final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
    final DateTime desde;
    final DateTime? hasta;
    switch (filtro) {
      case 'Ayer':
        desde = hoyInicio.subtract(const Duration(days: 1));
        hasta = hoyInicio;
      case '7 días':
        desde = ahora.subtract(const Duration(days: 7));
        hasta = null;
      case 'Hoy':
      default:
        desde = hoyInicio;
        hasta = null;
    }
    bool enRango(DateTime? d) => d != null && !d.isBefore(desde) && (hasta == null || d.isBefore(hasta));
    return registros.where((r) => enRango(r.hora) || enRango(r.ingreso) || enRango(r.salida)).toList();
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

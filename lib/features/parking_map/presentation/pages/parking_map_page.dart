import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/parking_cell.dart';
import '../../../../core/models/parking_zone.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_exception.dart';
import '../../../home/presentation/pages/home_shell.dart';
import '../widgets/cell_tile.dart';
import 'cell_detail_page.dart';

/// Mapa interactivo del parqueadero.
///
/// Con [vehicleParaAsignar] funciona como selector de celda dentro del
/// flujo de ingreso (el guarda elige dónde estacionar el vehículo recién
/// autorizado). Sin él, funciona como mapa de consulta general.
///
/// [soloLectura] evita que tocar una celda ocupada abra el detalle con
/// acciones de portería (reportar novedad, registrar salida): esas
/// acciones son exclusivas del guarda. El conductor solo puede
/// consultar la ocupación, nunca actuar sobre el vehículo de alguien más.
class ParkingMapPage extends StatefulWidget {
  final Vehicle? vehicleParaAsignar;
  final bool soloLectura;

  const ParkingMapPage({super.key, this.vehicleParaAsignar, this.soloLectura = false});

  @override
  State<ParkingMapPage> createState() => _ParkingMapPageState();
}

class _ParkingMapPageState extends State<ParkingMapPage> {
  final _repo = ParkingRepository.instance;
  late VehicleType _zonaSeleccionada = widget.vehicleParaAsignar?.tipo ?? VehicleType.carro;
  ParkingCell? _celdaSeleccionada;
  bool _asignando = false;

  bool get _esAsignacion => widget.vehicleParaAsignar != null;

  bool _cargandoAsignables = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    if (_esAsignacion) _cargarAsignables();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    if (_esAsignacion) _repo.limpiarAsignables();
    super.dispose();
  }

  /// Pide a la API qué celdas puede ocupar el vehículo ahora (descarta las
  /// retenidas por reservas ajenas) y preselecciona la que tenga reservada.
  Future<void> _cargarAsignables() async {
    setState(() => _cargandoAsignables = true);
    final reservada = await _repo.marcarAsignablesPara(widget.vehicleParaAsignar!);
    if (!mounted) return;
    setState(() {
      _cargandoAsignables = false;
      if (reservada != null) {
        _zonaSeleccionada = reservada.tipo;
        _celdaSeleccionada = reservada;
      }
    });
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  ParkingZone get _zona => _repo.zonaDe(_zonaSeleccionada);

  void _cambiarZona(VehicleType tipo) {
    setState(() {
      _zonaSeleccionada = tipo;
      _celdaSeleccionada = null;
    });
  }

  Future<void> _onCellTap(ParkingCell celda) async {
    if (!_esAsignacion && !widget.soloLectura && celda.esOcupada) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CellDetailPage(zona: _zona, celdaInicial: celda)));
      return;
    }
    if (_esAsignacion && celda.esLibre && celda.retenidaPorReserva) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La celda ${celda.codigoConParqueadero} está apartada por una reserva próxima: elige otra.')),
      );
      return;
    }
    setState(() => _celdaSeleccionada = celda);
  }

  Future<void> _confirmarAsignacion() async {
    final vehicle = widget.vehicleParaAsignar;
    final celda = _celdaSeleccionada;
    if (vehicle == null || celda == null || !celda.esAsignable || _asignando) return;
    setState(() => _asignando = true);
    try {
      final codigo = await _repo.registrarIngreso(vehicle, celda: celda);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingreso registrado · Celda $codigo')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _asignando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  IconData _iconoTipo(VehicleType tipo) {
    switch (tipo) {
      case VehicleType.carro:
        return Icons.directions_car_rounded;
      case VehicleType.moto:
        return Icons.two_wheeler_rounded;
    }
  }

  /// Filas de 5 celdas agrupadas por parqueadero: el mismo número de celda
  /// (p. ej. "M-01") existe en varios parqueaderos, así que sin la cabecera
  /// el guarda no sabría cuál está eligiendo.
  List<_SeccionParqueadero> _secciones(ParkingZone zona) {
    final porParqueadero = <int?, List<ParkingCell>>{};
    for (final celda in zona.celdas) {
      porParqueadero.putIfAbsent(celda.parqueaderoId, () => []).add(celda);
    }
    final secciones = <_SeccionParqueadero>[];
    for (final entrada in porParqueadero.entries) {
      final celdas = entrada.value;
      final filas = <List<ParkingCell>>[];
      for (var i = 0; i < celdas.length; i += _celdasPorFila) {
        filas.add(celdas.skip(i).take(_celdasPorFila).toList());
      }
      final parqueadero = _repo.parqueaderoPorId(entrada.key);
      secciones.add(_SeccionParqueadero(
        nombre: parqueadero?.nombreConTipo ?? celdas.first.parqueaderoNombre ?? 'Parqueadero',
        libres: celdas.where((c) => c.esLibre).length,
        filas: filas,
      ));
    }
    return secciones;
  }

  @override
  Widget build(BuildContext context) {
    final zona = _zona;
    final secciones = _secciones(zona);
    // Un solo parqueadero: no hace falta cabecera; el nombre ya va en la hoja inferior.
    final conCabeceras = secciones.length > 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackCircleButton(
                          color: Colors.white,
                          background: AppColors.darkSurface,
                          borderColor: AppColors.darkBorder,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _esAsignacion ? 'Elegir celda' : 'Mapa del parqueadero',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_esAsignacion)
                                Text.rich(
                                  TextSpan(
                                    text: 'Asignando a ',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkMuted),
                                    children: [
                                      TextSpan(
                                        text: ParkingRepository.formatea(widget.vehicleParaAsignar!.placa),
                                        style: AppTextStyles.mono(size: 12, color: AppColors.primaryAccent),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  '${_repo.cuposDisponibles} de ${_repo.cuposTotales} cupos libres',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: VehicleType.values.map((tipo) {
                        final seleccionada = tipo == _zonaSeleccionada;
                        final z = _repo.zonaDe(tipo);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: tipo != VehicleType.values.last ? 10 : 0),
                            child: _ZoneTab(
                              icon: _iconoTipo(tipo),
                              titulo: tipo.zona,
                              subtitulo: '${z.etiqueta} · ${z.disponibles} libres',
                              seleccionada: seleccionada,
                              onTap: () => _cambiarZona(tipo),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${zona.tipo.zona} · ${zona.etiqueta}'.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.darkMuted),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0x2639A900), borderRadius: BorderRadius.circular(999)),
                              child: Text('${zona.disponibles} libres', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryAccent)),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: const [
                            _Leyenda(color: Color(0xFF39A900), fondo: Color(0x4D39A900), texto: 'LIBRE'),
                            _Leyenda(color: Color(0xFFEF4444), fondo: Color(0x4DEF4444), texto: 'OCUPADA'),
                            _Leyenda(color: Color(0xFFF59E0B), fondo: Color(0xFF332A10), texto: 'RESERVA'),
                            _Leyenda(color: Color(0xFF94A3B8), fondo: Color(0xFF23262B), texto: 'MANT.'),
                            _Leyenda(color: Color(0xFF60A5FA), fondo: Color(0x2660A5FA), texto: 'PMR / SENA: preferencial'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: secciones.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _repo.cargando ? 'Cargando celdas…' : 'No hay celdas configuradas en esta zona.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.darkMuted, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                                children: [
                                  for (final seccion in secciones) ...[
                                    if (conCabeceras) _CabeceraParqueadero(nombre: seccion.nombre, libres: seccion.libres),
                                    for (var i = 0; i < seccion.filas.length; i++) ...[
                                      if (i > 0 && i % 4 == 0) const _Carril(),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 7),
                                        child: Row(children: _celdasFila(seccion.filas[i], _celdaSeleccionada, _onCellTap)),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BottomSheet(
                celda: _celdaSeleccionada,
                zonaNombre: _celdaSeleccionada?.parqueaderoNombre ?? '${zona.tipo.zona} · ${zona.etiqueta}',
                esAsignacion: _esAsignacion,
                asignando: _asignando || _cargandoAsignables,
                onAsignar: _confirmarAsignacion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Celdas por fila del mapa. Las filas incompletas se rellenan con huecos
/// para que una celda sola (parqueaderos pequeños) no se estire a todo el
/// ancho y todas las casillas midan lo mismo.
const _celdasPorFila = 5;

List<Widget> _celdasFila(List<ParkingCell> celdas, ParkingCell? seleccionada, ValueChanged<ParkingCell> onTap) {
  final widgets = <Widget>[];
  for (var i = 0; i < _celdasPorFila; i++) {
    if (i > 0) widgets.add(const SizedBox(width: 7));
    if (i >= celdas.length) {
      widgets.add(const Expanded(child: SizedBox()));
      continue;
    }
    widgets.add(Expanded(
      child: CellTile(
        cell: celdas[i],
        seleccionada: celdas[i] == seleccionada,
        onTap: () => onTap(celdas[i]),
      ),
    ));
  }
  return widgets;
}

class _SeccionParqueadero {
  final String nombre;
  final int libres;
  final List<List<ParkingCell>> filas;
  const _SeccionParqueadero({required this.nombre, required this.libres, required this.filas});
}

/// Cabecera de cada parqueadero dentro de la zona (solo cuando hay varios).
class _CabeceraParqueadero extends StatelessWidget {
  final String nombre;
  final int libres;
  const _CabeceraParqueadero({required this.nombre, required this.libres});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Row(
        children: [
          const Icon(Icons.local_parking_rounded, size: 14, color: AppColors.primaryAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nombre.toUpperCase(),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text('$libres libres', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.darkMuted)),
        ],
      ),
    );
  }
}

/// Pestaña de zona (carros / motos) en la parte superior del mapa.
class _ZoneTab extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final bool seleccionada;
  final VoidCallback onTap;

  const _ZoneTab({required this.icon, required this.titulo, required this.subtitulo, required this.seleccionada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = seleccionada ? Colors.white : AppColors.darkMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: seleccionada ? AppColors.primaryGradient : null,
        color: seleccionada ? null : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: seleccionada ? Colors.transparent : AppColors.darkBorder),
        boxShadow: seleccionada ? AppColors.primaryShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(subtitulo, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Separador de carril entre bloques de filas.
class _Carril extends StatelessWidget {
  const _Carril();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Container(height: 2, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.sync_alt_rounded, size: 14, color: Color(0xFF4B5563)),
          ),
          Expanded(child: Container(height: 2, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final Color fondo;
  final String texto;
  const _Leyenda({required this.color, required this.fondo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(3), border: Border.all(color: color, width: 1.5))),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.darkMuted, letterSpacing: 0.4)),
      ],
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final ParkingCell? celda;
  final String zonaNombre;
  final bool esAsignacion;
  final bool asignando;
  final VoidCallback onAsignar;

  const _BottomSheet({
    required this.celda,
    required this.zonaNombre,
    required this.esAsignacion,
    required this.asignando,
    required this.onAsignar,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionBar(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 14),
            if (celda == null)
              Row(
                children: [
                  const IconBadge(icon: Icons.touch_app_outlined, size: 40, iconSize: 20, background: AppColors.neutralSoft, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      esAsignacion ? 'Toca una celda libre para asignarla.' : 'Toca una celda del mapa para ver el detalle.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _fondoCodigo(celda!.estado), borderRadius: BorderRadius.circular(18)),
                    child: Text(celda!.codigo, style: AppTextStyles.mono(size: 15, color: _colorCodigo(celda!.estado))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Celda ${celda!.codigo}', style: AppTextStyles.heading3.copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(
                          celda!.usabilidad.esPreferencial ? '$zonaNombre · ${celda!.usabilidad.label}' : zonaNombre,
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(label: _estadoLabel(celda!.estado), tone: _tono(celda!.estado)),
                ],
              ),
              const SizedBox(height: 14),
              if (celda!.esOcupada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OCUPADA POR', style: AppTextStyles.overline.copyWith(color: AppColors.dangerDarker, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(color: AppColors.dangerDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                          children: [
                            TextSpan(text: celda!.placa ?? 'Vehículo sin placa', style: AppTextStyles.mono(size: 13.5, color: AppColors.dangerDark)),
                            if (celda!.conductorNombre != null) TextSpan(text: ' · ${celda!.conductorNombre}'),
                            if (celda!.desde != null) TextSpan(text: ' · desde ${_horaCorta(celda!.desde)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (celda!.esBloqueada && !celda!.reservadaParaVehiculo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.warningDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Esta celda no está disponible para asignar.', style: TextStyle(color: AppColors.warningDark, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              else if (esAsignacion) ...[
                if (celda!.reservadaParaVehiculo) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        Icon(Icons.bookmark_rounded, size: 18, color: AppColors.warningDark),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Reservada para este vehículo: es la que le corresponde.', style: TextStyle(color: AppColors.warningDark, fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: asignando ? null : onAsignar,
                    child: asignando
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 22),
                              SizedBox(width: 10),
                              Flexible(child: Text('Asignar y registrar ingreso', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                          ),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.primaryDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Celda libre y disponible.', style: TextStyle(color: AppColors.primaryDeep, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _fondoCodigo(CellStatus estado) {
    switch (estado) {
      case CellStatus.libre:
        return AppColors.primarySoft;
      case CellStatus.ocupada:
        return AppColors.dangerSoft;
      case CellStatus.reserva:
        return AppColors.warningSoft;
      case CellStatus.mantenimiento:
        return AppColors.neutralSoft;
    }
  }

  Color _colorCodigo(CellStatus estado) {
    switch (estado) {
      case CellStatus.libre:
        return AppColors.primaryDark;
      case CellStatus.ocupada:
        return AppColors.dangerDarker;
      case CellStatus.reserva:
        return AppColors.warningDark;
      case CellStatus.mantenimiento:
        return AppColors.textSecondary;
    }
  }

  ChipTone _tono(CellStatus estado) {
    switch (estado) {
      case CellStatus.libre:
        return ChipTone.success;
      case CellStatus.ocupada:
        return ChipTone.danger;
      case CellStatus.reserva:
        return ChipTone.warning;
      case CellStatus.mantenimiento:
        return ChipTone.neutral;
    }
  }

  String _estadoLabel(CellStatus estado) {
    switch (estado) {
      case CellStatus.libre:
        return 'Libre';
      case CellStatus.ocupada:
        return 'Ocupada';
      case CellStatus.reserva:
        return 'Reserva';
      case CellStatus.mantenimiento:
        return 'Mantenimiento';
    }
  }

  String _horaCorta(DateTime? d) {
    if (d == null) return '--';
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$h:$m $ampm';
  }
}

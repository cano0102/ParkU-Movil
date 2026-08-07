import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/parking_cell.dart';
import '../../../../core/models/parking_zone.dart';
import '../../../../core/models/vehicle.dart';
import '../../../home/presentation/pages/home_shell.dart';
import '../widgets/cell_tile.dart';
import 'cell_detail_page.dart';

const _fondoOscuro = Color(0xFF14181D);
const _tarjetaOscura = Color(0xFF1C2127);
const _bordeOscuro = Color(0xFF2A3038);

/// Mapa interactivo del parqueadero.
///
/// Con [vehicleParaAsignar] funciona como selector de celda dentro del
/// flujo de ingreso (el guarda elige dónde estacionar el vehículo recién
/// autorizado). Sin él, funciona como mapa de consulta general accesible
/// desde el inicio: tocar una celda ocupada abre su detalle completo.
class ParkingMapPage extends StatefulWidget {
  final Vehicle? vehicleParaAsignar;

  const ParkingMapPage({super.key, this.vehicleParaAsignar});

  @override
  State<ParkingMapPage> createState() => _ParkingMapPageState();
}

class _ParkingMapPageState extends State<ParkingMapPage> {
  final _repo = ParkingRepository.instance;
  late VehicleType _zonaSeleccionada = widget.vehicleParaAsignar?.tipo ?? VehicleType.carro;
  ParkingCell? _celdaSeleccionada;
  bool _asignando = false;

  bool get _esAsignacion => widget.vehicleParaAsignar != null;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
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
    if (!_esAsignacion && celda.esOcupada) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CellDetailPage(zona: _zona, celdaInicial: celda)));
      return;
    }
    setState(() => _celdaSeleccionada = celda);
  }

  Future<void> _confirmarAsignacion() async {
    final vehicle = widget.vehicleParaAsignar;
    final celda = _celdaSeleccionada;
    if (vehicle == null || celda == null || !celda.esLibre || _asignando) return;
    setState(() => _asignando = true);
    final codigo = _repo.registrarIngreso(vehicle, celda: celda);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ingreso registrado · Celda $codigo')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  IconData _iconoTipo(VehicleType tipo) {
    switch (tipo) {
      case VehicleType.carro:
        return Icons.directions_car;
      case VehicleType.moto:
        return Icons.two_wheeler;
      case VehicleType.camion:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zona = _zona;
    final filas = <List<ParkingCell>>[];
    for (var i = 0; i < zona.celdas.length; i += 5) {
      filas.add(zona.celdas.skip(i).take(5).toList());
    }

    return Scaffold(
      backgroundColor: _fondoOscuro,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_esAsignacion ? 'Elegir celda' : 'Mapa del parqueadero', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                            if (_esAsignacion)
                              Text.rich(
                                TextSpan(
                                  text: 'Asignando a ',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  children: [
                                    TextSpan(
                                      text: ParkingRepository.formatea(widget.vehicleParaAsignar!.placa),
                                      style: AppTextStyles.mono(size: 12, color: const Color(0xFFB3E6A1)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: VehicleType.values.map((tipo) {
                      final seleccionada = tipo == _zonaSeleccionada;
                      final z = _repo.zonaDe(tipo);
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: tipo != VehicleType.values.last ? 8 : 0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _cambiarZona(tipo),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: seleccionada ? AppColors.primary : _tarjetaOscura,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(_iconoTipo(tipo), size: 20, color: seleccionada ? Colors.white : const Color(0xFF94A3B8)),
                                  const SizedBox(height: 3),
                                  Text(tipo.zona, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: seleccionada ? Colors.white : const Color(0xFF94A3B8))),
                                  Text(z.etiqueta, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: (seleccionada ? Colors.white : const Color(0xFF94A3B8)).withValues(alpha: 0.8))),
                                ],
                              ),
                            ),
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
                decoration: BoxDecoration(color: _tarjetaOscura, borderRadius: BorderRadius.circular(22), border: Border.all(color: _bordeOscuro)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${zona.tipo.zona} · ${zona.etiqueta}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Color(0xFF94A3B8))),
                          Text('${zona.disponibles} libres', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB3E6A1))),
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                        itemCount: filas.length,
                        itemBuilder: (context, index) {
                          final esCarril = index > 0 && index % 4 == 0;
                          final fila = Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              children: _celdasFila(filas[index], _celdaSeleccionada, _onCellTap),
                            ),
                          );
                          if (!esCarril) return fila;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(child: Container(height: 2, color: const Color(0xFF4B5563))),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(Icons.sync_alt, size: 14, color: Color(0xFF4B5563)),
                                    ),
                                    Expanded(child: Container(height: 2, color: const Color(0xFF4B5563))),
                                  ],
                                ),
                              ),
                              fila,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomSheet(
              celda: _celdaSeleccionada,
              zonaNombre: '${zona.tipo.zona} · ${zona.etiqueta}',
              esAsignacion: _esAsignacion,
              asignando: _asignando,
              onAsignar: _confirmarAsignacion,
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _celdasFila(List<ParkingCell> celdas, ParkingCell? seleccionada, ValueChanged<ParkingCell> onTap) {
  final widgets = <Widget>[];
  for (var i = 0; i < celdas.length; i++) {
    if (i > 0) widgets.add(const SizedBox(width: 7));
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
        Container(width: 9, height: 9, decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(3), border: Border.all(color: color, width: 1.5))),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
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
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 14),
          if (celda == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Toca una celda del mapa para ver el detalle.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                  child: Text(celda!.codigo, style: AppTextStyles.mono(size: 15, color: AppColors.primaryDark)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Celda ${celda!.codigo}', style: AppTextStyles.heading3.copyWith(fontSize: 17)),
                      Text('${_estadoLabel(celda!.estado)} · $zonaNombre', style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
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
                    Text('OCUPADA POR', style: AppTextStyles.overline.copyWith(color: AppColors.dangerDarker, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: AppColors.dangerDark, fontSize: 14, fontWeight: FontWeight.w700),
                        children: [
                          TextSpan(text: celda!.placa ?? '', style: AppTextStyles.mono(size: 14, color: AppColors.dangerDark)),
                          TextSpan(text: ' · ${celda!.conductorNombre ?? ''} · desde ${_horaCorta(celda!.desde)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (celda!.esBloqueada)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
                child: Text('Esta celda no está disponible para asignar.', style: TextStyle(color: const Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w700)),
              )
            else if (esAsignacion)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: asignando ? null : onAsignar,
                  child: asignando
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 22),
                            SizedBox(width: 10),
                            Text('Asignar y registrar ingreso'),
                          ],
                        ),
                ),
              )
            else
              Text('Celda libre.', style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
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

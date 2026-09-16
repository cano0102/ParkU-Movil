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
import '../../../incidents/presentation/pages/report_incident_page.dart';
import '../widgets/cell_tile.dart';

/// Detalle de una celda ocupada: quién la ocupa y acciones rápidas
/// (reportar novedad o registrar la salida) sin pasar por el buscador
/// de placas. Se abre al tocar una celda ocupada en el mapa general.
class CellDetailPage extends StatelessWidget {
  final ParkingZone zona;
  final ParkingCell celdaInicial;

  const CellDetailPage({super.key, required this.zona, required this.celdaInicial});

  void _reportarNovedad(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportIncidentPage(
          tipoInicial: TipoNovedadUi.otro,
          celdaContexto: celdaInicial.codigo,
          celdaId: celdaInicial.id,
          placaContexto: celdaInicial.placa,
        ),
      ),
    );
  }

  Future<void> _registrarSalida(BuildContext context) async {
    final placa = celdaInicial.placa;
    if (placa == null) return;
    try {
      await ParkingRepository.instance.registrarSalida(placa);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salida registrada · $placa')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _permanencia() {
    final d = celdaInicial.permanencia;
    if (d == null) return '--';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  String _horaIngreso() {
    final desde = celdaInicial.desde;
    if (desde == null) return '--';
    final h = desde.hour % 12 == 0 ? 12 : desde.hour % 12;
    final m = desde.minute.toString().padLeft(2, '0');
    final ampm = desde.hour >= 12 ? 'p. m.' : 'a. m.';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.55,
                      // OverflowBox: esta cuadrícula es solo un fondo decorativo
                      // detrás del velo oscuro; en pantallas bajas puede pedir
                      // más alto de lo que el Stack (con fit: expand) le da, así
                      // que dejamos que se recorte en vez de forzar un layout
                      // que rompa con overflow.
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                          child: _MiniGrid(celdas: zona.celdas),
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xB30A0D11), Color(0xE60A0D11)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
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
                                  'Celda ${celdaInicial.codigo}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '${zona.tipo.zona} · ${zona.etiqueta}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkMuted),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              BottomActionBar(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconBadge(
                          icon: zona.tipo == VehicleType.moto ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
                          size: 54,
                          iconSize: 26,
                          background: AppColors.dangerSoft,
                          color: AppColors.dangerDarker,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: PlateBox(placa: celdaInicial.placa ?? '—', size: 18),
                              ),
                              const SizedBox(height: 6),
                              Text('Ocupada · Celda ${celdaInicial.codigo}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusChip(label: 'Dentro', tone: ChipTone.danger),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: DataField(label: 'Conductor', value: celdaInicial.conductorNombre ?? '—', icon: Icons.person_outline_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: DataField(label: 'Rol', value: celdaInicial.conductorRol ?? '—', icon: Icons.badge_outlined)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: DataField(label: 'Ingreso', value: _horaIngreso(), icon: Icons.login_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: DataField(label: 'Permanencia', value: _permanencia(), icon: Icons.schedule_rounded)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), padding: const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () => _reportarNovedad(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.report_gmailerrorred_rounded, size: 20),
                                SizedBox(width: 8),
                                Flexible(child: Text('Novedad', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54), padding: const EdgeInsets.symmetric(horizontal: 8)),
                            onPressed: () => _registrarSalida(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, size: 20),
                                SizedBox(width: 8),
                                Flexible(child: Text('Registrar salida', overflow: TextOverflow.ellipsis, maxLines: 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula de celdas de solo lectura, usada como fondo atenuado.
class _MiniGrid extends StatelessWidget {
  final List<ParkingCell> celdas;
  const _MiniGrid({required this.celdas});

  @override
  Widget build(BuildContext context) {
    final filas = <List<ParkingCell>>[];
    for (var i = 0; i < celdas.length && i < 20; i += 5) {
      filas.add(celdas.skip(i).take(5).toList());
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          for (final fila in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  for (var i = 0; i < fila.length; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(child: CellTile(cell: fila[i])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/parking_cell.dart';
import '../../../../core/models/parking_zone.dart';
import '../../../../core/models/vehicle.dart';
import '../widgets/cell_tile.dart';

/// Detalle de una celda ocupada: quién la ocupa y acciones rápidas
/// (reportar novedad o registrar la salida) sin pasar por el buscador
/// de placas. Se abre al tocar una celda ocupada en el mapa general.
class CellDetailPage extends StatelessWidget {
  final ParkingZone zona;
  final ParkingCell celdaInicial;

  const CellDetailPage({super.key, required this.zona, required this.celdaInicial});

  void _reportarNovedad(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reportar novedad'),
        content: Text('Se registrará una novedad sobre la celda ${celdaInicial.codigo}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _registrarSalida(BuildContext context) {
    final placa = celdaInicial.placa;
    if (placa == null) return;
    ParkingRepository.instance.registrarSalida(placa);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada · $placa')),
    );
    Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: const Color(0xFF14181D),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.62,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                      child: _MiniGrid(celdas: zona.celdas),
                    ),
                  ),
                  Container(color: const Color(0xA60A0D11)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${zona.tipo.zona} · ${zona.etiqueta}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(18)),
                        child: Text(celdaInicial.codigo, style: AppTextStyles.mono(size: 15, color: AppColors.dangerDarker)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(celdaInicial.placa ?? '—', style: AppTextStyles.plate(size: 22)),
                            Text('Ocupada · ${zona.tipo.zona} · ${zona.etiqueta}', style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
                        child: Text('Dentro', style: AppTextStyles.caption.copyWith(color: AppColors.dangerDarker)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _dato('Conductor', celdaInicial.conductorNombre ?? '—')),
                      Expanded(child: _dato('Rol', celdaInicial.conductorRol ?? '—')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _dato('Ingreso', _horaIngreso())),
                      Expanded(child: _dato('Permanencia', _permanencia())),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(color: AppColors.border, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _reportarNovedad(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.report, size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('Novedad', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _registrarSalida(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 20),
                              SizedBox(width: 8),
                              Text('Registrar salida'),
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
    );
  }

  Widget _dato(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
      ],
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

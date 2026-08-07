import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart' show ParkedVehicle;

class ExitRegisterPage extends StatefulWidget {
  const ExitRegisterPage({super.key});

  @override
  State<ExitRegisterPage> createState() => _ExitRegisterPageState();
}

class _ExitRegisterPageState extends State<ExitRegisterPage> {
  final _repo = ParkingRepository.instance;
  final _controller = TextEditingController();
  ParkedVehicle? _encontrado;
  bool _buscado = false;
  bool _placaCoincide = true;
  bool _sinNovedades = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    setState(() {
      _buscado = texto.trim().isNotEmpty;
      _encontrado = _buscado ? _repo.buscarDentro(texto) : null;
    });
  }

  void _escanearRapido() {
    final ocupadas = _repo.zonas.expand((z) => z.celdas).where((c) => c.esOcupada).toList();
    if (ocupadas.isEmpty) return;
    final celda = ocupadas[Random().nextInt(ocupadas.length)];
    _controller.text = ParkingRepository.normaliza(celda.placa!);
    _buscar(_controller.text);
  }

  void _confirmarSalida() {
    if (_encontrado == null) return;
    _repo.registrarSalida(_encontrado!.placa);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada · ${ParkingRepository.formatea(ParkingRepository.normaliza(_encontrado!.placa))}')),
    );
    Navigator.of(context).pop();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final puedeConfirmar = _encontrado != null && _placaCoincide;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text('Registrar salida', style: AppTextStyles.title, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  TextField(
                    controller: _controller,
                    onChanged: _buscar,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTextStyles.plate(size: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar por placa',
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textPlaceholder),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.photo_camera, color: AppColors.primary),
                        onPressed: _escanearRapido,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_buscado && _encontrado == null)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.dangerSoftBorder)),
                      child: Text(
                        'No hay un vehículo dentro del parqueadero con esa placa.',
                        style: TextStyle(color: AppColors.dangerDark, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (_encontrado != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(_encontrado!.placa, style: AppTextStyles.plate(size: 26)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                                child: Text('Dentro', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _dato('Conductor', _encontrado!.conductorNombre)),
                              Expanded(child: _dato('Celda', _encontrado!.celda)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _dato('Hora de ingreso', TimeOfDay.fromDateTime(_encontrado!.horaIngreso).format(context))),
                              Expanded(child: _dato('Permanencia', _formatDuration(_encontrado!.permanencia))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIFICACIÓN DE SALIDA', style: AppTextStyles.overline),
                          const SizedBox(height: 12),
                          _checkRow('La placa coincide con el ingreso', _placaCoincide, (v) => setState(() => _placaCoincide = v)),
                          const SizedBox(height: 12),
                          _checkRow('Sin novedades durante la permanencia', _sinNovedades, (v) => setState(() => _sinNovedades = v)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: ElevatedButton(
                onPressed: puedeConfirmar ? _confirmarSalida : null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 22),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text('Confirmar salida', overflow: TextOverflow.ellipsis, maxLines: 1),
                    ),
                  ],
                ),
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

  Widget _checkRow(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: value ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: value ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: value ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

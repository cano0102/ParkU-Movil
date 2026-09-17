import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart' show ParkedVehicle;
import '../../../../core/network/api_exception.dart';

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
  bool _buscando = false;
  int _busquedaId = 0;
  bool _placaCoincide = true;
  bool _sinNovedades = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscar(String texto) async {
    final id = ++_busquedaId;
    final buscado = texto.trim().isNotEmpty;
    setState(() {
      _buscado = buscado;
      _buscando = buscado;
      if (!buscado) _encontrado = null;
    });
    if (!buscado) return;
    ParkedVehicle? resultado;
    try {
      resultado = await _repo.buscarDentro(texto);
    } catch (_) {
      resultado = null;
    }
    if (!mounted || id != _busquedaId) return;
    setState(() {
      _encontrado = resultado;
      _buscando = false;
    });
  }

  void _escanearRapido() {
    final ocupadas = _repo.zonas.expand((z) => z.celdas).where((c) => c.esOcupada && c.placa != null).toList();
    if (ocupadas.isEmpty) return;
    final celda = ocupadas[Random().nextInt(ocupadas.length)];
    _controller.text = ParkingRepository.normaliza(celda.placa!);
    _buscar(_controller.text);
  }

  Future<void> _confirmarSalida() async {
    if (_encontrado == null) return;
    try {
      await _repo.registrarSalida(_encontrado!.placa);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salida registrada · ${ParkingRepository.formatea(ParkingRepository.normaliza(_encontrado!.placa))}')));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageTopBar(title: 'Registrar salida', subtitle: 'Busca el vehículo que está saliendo', showBack: true, large: false),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                      child: TextField(
                        controller: _controller,
                        onChanged: _buscar,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
                        style: AppTextStyles.plate(size: 15, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Buscar por placa',
                          counterText: '',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textPlaceholder),
                          suffixIcon: IconButton(
                            tooltip: 'Escanear placa',
                            icon: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                            onPressed: _escanearRapido,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: _buildResultado(context)),
                  ],
                ),
              ),
              BottomActionBar(
                child: ElevatedButton(
                  onPressed: puedeConfirmar ? _confirmarSalida : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 22),
                      SizedBox(width: 10),
                      Flexible(child: Text('Confirmar salida', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultado(BuildContext context) {
    if (_buscando) {
      return const Padding(
        key: ValueKey('cargando'),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (!_buscado) {
      return const EmptyState(
        key: ValueKey('vacio'),
        icon: Icons.search_rounded,
        title: 'Escribe o escanea la placa',
        subtitle: 'Solo aparecerán vehículos que estén dentro del parqueadero en este momento.',
      );
    }
    if (_encontrado == null) {
      return AppCard(
        key: const ValueKey('sin-resultado'),
        color: AppColors.dangerSoft,
        borderColor: AppColors.dangerSoftBorder,
        child: Row(
          children: [
            const IconBadge(icon: Icons.search_off_rounded, size: 40, iconSize: 21, background: Colors.white, color: AppColors.dangerDarker),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No hay un vehículo dentro del parqueadero con esa placa.',
                style: TextStyle(color: AppColors.dangerDark, fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    final v = _encontrado!;
    return Column(
      key: const ValueKey('resultado'),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PlateBox(placa: v.placa, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusChip(label: 'Dentro', tone: ChipTone.success),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DataField(label: 'Conductor', value: v.conductorNombre, icon: Icons.person_outline_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DataField(label: 'Celda', value: v.celda, mono: true, icon: Icons.local_parking_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DataField(label: 'Hora de ingreso', value: TimeOfDay.fromDateTime(v.horaIngreso).format(context), icon: Icons.login_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DataField(label: 'Permanencia', value: _formatDuration(v.permanencia), icon: Icons.schedule_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VERIFICACIÓN DE SALIDA', style: AppTextStyles.overline),
              const SizedBox(height: 12),
              _CheckRow(label: 'La placa coincide con el ingreso', value: _placaCoincide, onChanged: (v) => setState(() => _placaCoincide = v)),
              const SizedBox(height: 10),
              _CheckRow(label: 'Sin novedades durante la permanencia', value: _sinNovedades, onChanged: (v) => setState(() => _sinNovedades = v)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: value ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_exception.dart';
import 'vehicle_authorized_page.dart';
import 'vehicle_denied_page.dart';

class ConfirmPlatePage extends StatefulWidget {
  final String placaDetectada;

  const ConfirmPlatePage({super.key, required this.placaDetectada});

  @override
  State<ConfirmPlatePage> createState() => _ConfirmPlatePageState();
}

class _ConfirmPlatePageState extends State<ConfirmPlatePage> {
  late String _placa;
  VehicleType _tipoSeleccionado = VehicleType.carro;
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    _placa = widget.placaDetectada;
    _precargarTipo();
  }

  Future<void> _precargarTipo() async {
    try {
      final registrado = await ParkingRepository.instance.buscarVehiculo(_placa);
      if (mounted && registrado != null) setState(() => _tipoSeleccionado = registrado.tipo);
    } catch (_) {
      // Solo es una sugerencia inicial del selector de tipo: si falla, el
      // guarda igual puede elegirlo a mano.
    }
  }

  Future<void> _editarPlaca() async {
    final controller = TextEditingController(text: _placa);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corregir placa'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.characters, maxLength: 8, style: AppTextStyles.plate(size: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    if (resultado != null && resultado.trim().isNotEmpty) {
      setState(() => _placa = ParkingRepository.normaliza(resultado));
    }
  }

  Future<void> _verificar() async {
    if (_verificando) return;
    setState(() => _verificando = true);
    try {
      final vehiculo = await ParkingRepository.instance.buscarVehiculo(_placa);
      if (!mounted) return;
      if (vehiculo != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VehicleAuthorizedPage(vehicle: vehiculo)));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VehicleDeniedPage(placa: _placa)));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _verificando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final placaFormateada = ParkingRepository.formatea(_placa);
    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageTopBar(title: 'Confirmar placa', subtitle: 'Paso 2 de 3 · Verificación', showBack: true, large: false),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F2933), Color(0xFF0F1419)]),
                        boxShadow: AppColors.cardShadow,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_back_outlined, color: Colors.white.withValues(alpha: 0.35), size: 30),
                          const SizedBox(height: 8),
                          Text('CAPTURA DE LA PLACA', style: AppTextStyles.mono(size: 10, color: Colors.white.withValues(alpha: 0.45))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('PLACA DETECTADA', style: AppTextStyles.overline, overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                              const SizedBox(width: 8),
                              const StatusChip(label: '98% confianza', tone: ChipTone.success),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _editarPlaca,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 82,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft.withValues(alpha: 0.5),
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      PlateBox(placa: placaFormateada, size: 26),
                                      const SizedBox(width: 14),
                                      const IconBadge(icon: Icons.edit_rounded, size: 36, iconSize: 18, background: Colors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textPlaceholder),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Toca la placa para corregir cualquier carácter antes de continuar.', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'TIPO DE VEHÍCULO'),
                    const SizedBox(height: 10),
                    VehicleTypeSelector(selected: _tipoSeleccionado, onChanged: (tipo) => setState(() => _tipoSeleccionado = tipo), height: 74),
                  ],
                ),
              ),
              BottomActionBar(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Repetir', overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: _verificando ? null : _verificar,
                        child: _verificando
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(child: Text('Verificar vehículo', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),
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

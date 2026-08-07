import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
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

  @override
  void initState() {
    super.initState();
    _placa = widget.placaDetectada;
    final registrado = ParkingRepository.instance.buscarVehiculo(_placa);
    if (registrado != null) _tipoSeleccionado = registrado.tipo;
  }

  Future<void> _editarPlaca() async {
    final controller = TextEditingController(text: _placa);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Corregir placa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
        ),
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

  void _verificar() {
    final vehiculo = ParkingRepository.instance.buscarVehiculo(_placa);
    if (vehiculo != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VehicleAuthorizedPage(vehicle: vehiculo)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => VehicleDeniedPage(placa: _placa)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final placaFormateada = ParkingRepository.formatea(_placa);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 22, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('Confirmar placa', style: AppTextStyles.title),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Container(
                        color: const Color(0xFFDDE4E7),
                        alignment: Alignment.center,
                        child: Text(
                          'CAPTURA DE LA PLACA\n[ foto tomada ]',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.mono(size: 11, color: const Color(0xFF7A8790)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('PLACA DETECTADA', style: AppTextStyles.overline),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
                              child: Text('98% confianza', style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _editarPlaca,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 76,
                            decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 2), borderRadius: BorderRadius.circular(18)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(placaFormateada, style: AppTextStyles.plate(size: 32)),
                                const SizedBox(width: 14),
                                const Icon(Icons.edit, color: AppColors.primary, size: 22),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Toca la placa para corregir cualquier carácter antes de continuar.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('TIPO DE VEHÍCULO', style: AppTextStyles.overline),
                  const SizedBox(height: 10),
                  Row(
                    children: VehicleType.values.map((tipo) {
                      final seleccionado = tipo == _tipoSeleccionado;
                      final icon = tipo == VehicleType.carro
                          ? Icons.directions_car
                          : tipo == VehicleType.moto
                              ? Icons.two_wheeler
                              : Icons.local_shipping;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: tipo != VehicleType.values.last ? 10 : 0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setState(() => _tipoSeleccionado = tipo),
                            child: Container(
                              height: 74,
                              decoration: BoxDecoration(
                                color: seleccionado ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: seleccionado ? null : Border.all(color: AppColors.border, width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon, size: 24, color: seleccionado ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(height: 4),
                                  Text(tipo.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: seleccionado ? Colors.white : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Repetir', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _verificar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Verificar vehículo'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
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
    );
  }
}

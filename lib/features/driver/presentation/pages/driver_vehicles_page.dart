import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';

/// "Mis vehículos": los vehículos registrados a nombre del conductor,
/// con su estado actual, y la opción de registrar uno nuevo.
class DriverVehiclesPage extends StatefulWidget {
  const DriverVehiclesPage({super.key});

  @override
  State<DriverVehiclesPage> createState() => _DriverVehiclesPageState();
}

class _DriverVehiclesPageState extends State<DriverVehiclesPage> {
  final _repo = ParkingRepository.instance;

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

  Future<void> _registrarVehiculo() async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RegistrarVehiculoSheet(),
    );
    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo registrado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = _repo.misVehiculos();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Mis vehículos', style: AppTextStyles.heading2, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _registrarVehiculo,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.add, size: 22, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: vehiculos.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_car_outlined, size: 40, color: AppColors.textPlaceholder),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no tienes vehículos registrados.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(onPressed: _registrarVehiculo, child: const Text('Registrar vehículo')),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                      itemCount: vehiculos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = vehiculos[index];
                        final celda = _repo.celdaDePlaca(v.placa);
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                                    child: Icon(_iconoTipo(v.tipo), color: AppColors.primaryDark, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(ParkingRepository.formatea(v.placa), style: AppTextStyles.plate(size: 22)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: celda != null ? AppColors.primarySoft : AppColors.neutralSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      celda != null ? 'Dentro' : 'Fuera',
                                      style: AppTextStyles.caption.copyWith(color: celda != null ? AppColors.primaryDark : AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _dato('Marca y línea', v.marcaLinea)),
                                  Expanded(child: _dato('Color', v.color)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: _dato('SOAT', v.soatVigente ? 'Vigente' : 'Vencido', color: v.soatVigente ? AppColors.success : AppColors.danger)),
                                  Expanded(child: _dato('Celda', celda?.codigo ?? '—')),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 14, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _RegistrarVehiculoSheet extends StatefulWidget {
  const _RegistrarVehiculoSheet();

  @override
  State<_RegistrarVehiculoSheet> createState() => _RegistrarVehiculoSheetState();
}

class _RegistrarVehiculoSheetState extends State<_RegistrarVehiculoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _colorController = TextEditingController();
  VehicleType _tipo = VehicleType.carro;
  bool _soatVigente = true;
  String? _error;

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final ok = ParkingRepository.instance.registrarVehiculo(
      placa: _placaController.text,
      tipo: _tipo,
      marcaLinea: _marcaController.text.trim(),
      color: _colorController.text.trim(),
      soatVigente: _soatVigente,
    );
    if (!ok) {
      setState(() => _error = 'Esa placa ya está registrada en el sistema.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999)), alignment: Alignment.center),
                const SizedBox(height: 18),
                Text('Registrar vehículo', style: AppTextStyles.heading3),
                const SizedBox(height: 18),
                Text('Tipo de vehículo', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Row(
                  children: VehicleType.values.map((tipo) {
                    final seleccionado = tipo == _tipo;
                    final icon = tipo == VehicleType.carro
                        ? Icons.directions_car
                        : tipo == VehicleType.moto
                            ? Icons.two_wheeler
                            : Icons.local_shipping;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: tipo != VehicleType.values.last ? 10 : 0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _tipo = tipo),
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: seleccionado ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: seleccionado ? null : Border.all(color: AppColors.border, width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: 22, color: seleccionado ? Colors.white : AppColors.textSecondary),
                                const SizedBox(height: 4),
                                Text(tipo.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: seleccionado ? Colors.white : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Placa', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placaController,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTextStyles.plate(size: 16),
                  decoration: const InputDecoration(hintText: 'Ej. WGY482'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa la placa';
                    if (ParkingRepository.normaliza(value).length < 5) return 'Placa inválida';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Marca y línea', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _marcaController,
                            decoration: const InputDecoration(hintText: 'Ej. Mazda 3'),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Color', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(hintText: 'Ej. Gris'),
                            validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _soatVigente,
                  onChanged: (value) => setState(() => _soatVigente = value),
                  title: Text('SOAT vigente', style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _guardar, child: const Text('Guardar vehículo')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

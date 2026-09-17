import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';

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
        return Icons.directions_car_rounded;
      case VehicleType.moto:
        return Icons.two_wheeler_rounded;
    }
  }

  Future<void> _registrarVehiculo() async {
    final resultado = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (_) => const _RegistrarVehiculoSheet());
    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehículo registrado correctamente')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = _repo.misVehiculos();
    final puedeVolver = Navigator.of(context).canPop();

    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageTopBar(
                title: 'Mis vehículos',
                subtitle: vehiculos.isEmpty ? 'Ninguno registrado' : '${vehiculos.length} registrado${vehiculos.length == 1 ? '' : 's'}',
                showBack: puedeVolver,
                trailing: TopBarActionButton(icon: Icons.add_rounded, filled: true, onTap: _registrarVehiculo),
              ),
              Expanded(
                child: vehiculos.isEmpty
                    ? EmptyState(
                        icon: Icons.directions_car_outlined,
                        title: 'Aún no tienes vehículos registrados',
                        subtitle: 'Registra tu carro o moto para agilizar tu ingreso en portería.',
                        action: ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                          onPressed: _registrarVehiculo,
                          child: const Text('Registrar vehículo'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: vehiculos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final v = vehiculos[index];
                          final celda = _repo.celdaDePlaca(v.placa);
                          final dentro = celda != null;
                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IconBadge(icon: _iconoTipo(v.tipo), size: 46, iconSize: 23),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(v.tipo.label.toUpperCase(), style: AppTextStyles.overline.copyWith(fontSize: 10)),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: PlateBox(placa: ParkingRepository.formatea(v.placa), size: 17),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusChip(label: dentro ? 'Dentro' : 'Fuera', tone: dentro ? ChipTone.success : ChipTone.neutral),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                const Divider(),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DataField(label: 'Marca y línea', value: v.marcaLinea),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DataField(label: 'Color', value: v.color),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DataField(
                                        label: 'SOAT',
                                        value: v.soatVigente ? 'Vigente' : 'Vencido',
                                        valueColor: v.soatVigente ? AppColors.success : AppColors.danger,
                                        icon: v.soatVigente ? Icons.verified_rounded : Icons.error_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DataField(label: 'Celda', value: celda?.codigoConParqueadero ?? '—', mono: true),
                                    ),
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
      ),
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
  bool _guardando = false;

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ParkingRepository.instance.registrarVehiculo(
        placa: _placaController.text,
        tipo: _tipo,
        marcaLinea: _marcaController.text.trim(),
        color: _colorController.text.trim(),
        soatVigente: _soatVigente,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        // El backend solo deja registrar vehículos desde portería/administración
        // (403 para un Conductor): se muestra tal cual el motivo que da la API.
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: 18),
                Text('Registrar vehículo', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text('Los datos deben coincidir con la tarjeta de propiedad.', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 18),
                Text('Tipo de vehículo', style: AppTextStyles.label),
                const SizedBox(height: 8),
                VehicleTypeSelector(selected: _tipo, onChanged: (tipo) => setState(() => _tipo = tipo)),
                const SizedBox(height: 16),
                Text('Placa', style: AppTextStyles.label),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placaController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: AppTextStyles.plate(size: 16),
                  decoration: InputDecoration(
                    hintText: _tipo == VehicleType.moto ? 'Ej. ABC12D' : 'Ej. WGY482',
                    prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textPlaceholder),
                    counterText: '',
                  ),
                  validator: (value) => Validators.placa(value, _tipo),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Marca y línea', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _marcaController,
                            maxLength: 100,
                            decoration: const InputDecoration(hintText: 'Ej. Mazda 3', counterText: ''),
                            validator: (value) => Validators.requerido(value, 'la marca y línea', max: 100),
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
                            maxLength: 50,
                            decoration: const InputDecoration(hintText: 'Ej. Gris', counterText: ''),
                            validator: (value) => Validators.requerido(value, 'el color', max: 50),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  radius: 16,
                  elevated: false,
                  padding: EdgeInsets.zero,
                  child: SettingsTile(icon: Icons.verified_outlined, title: 'SOAT vigente', value: _soatVigente, onChanged: (value) => setState(() => _soatVigente = value)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.dangerDarker),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.dangerDarker)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Guardar vehículo'),
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

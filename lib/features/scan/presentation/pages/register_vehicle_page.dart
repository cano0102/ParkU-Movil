import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import 'vehicle_authorized_page.dart';

const List<(String, String)> _tiposDocumento = [
  ('CC', 'Cédula de ciudadanía'),
  ('CE', 'Cédula de extranjería'),
  ('TI', 'Tarjeta de identidad'),
  ('PASAPORTE', 'Pasaporte'),
  ('PEP', 'Permiso especial de permanencia'),
  ('NIT', 'NIT'),
];

/// Da de alta un vehículo (y, si hace falta, a su conductor) directamente
/// desde portería, cuando la placa escaneada no coincide con ninguna ficha
/// registrada. Es el equivalente móvil del asistente "Estacionar vehículo"
/// del panel web: allí, si la placa no tiene dueño, el mismo formulario pide
/// marca/color y busca o crea al conductor sin salir del flujo, en vez de
/// dejar el ingreso solo como "visitante" o "denegado".
class RegisterVehiclePage extends StatefulWidget {
  final String placaSugerida;
  final VehicleType tipoSugerido;

  const RegisterVehiclePage({super.key, required this.placaSugerida, required this.tipoSugerido});

  @override
  State<RegisterVehiclePage> createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _tipo;
  late final TextEditingController _placaController;
  final _marcaController = TextEditingController();
  final _colorController = TextEditingController();
  final _modeloController = TextEditingController();
  bool _vehiculoSena = false;

  String _tipoDocumento = 'CC';
  final _documentoController = TextEditingController();
  bool _buscandoConductor = false;
  bool _conductorBuscado = false;
  Map<String, dynamic>? _conductorEncontrado;
  final _nombreConductorController = TextEditingController();
  final _correoConductorController = TextEditingController();
  final _telefonoConductorController = TextEditingController();

  bool _guardando = false;
  String? _error;

  bool get _conductorInactivo => _conductorEncontrado != null && _conductorEncontrado!['estado'] == false;

  /// Listo para registrar el vehículo: ya se buscó el conductor y, o se
  /// identificó uno activo, o se completó su nombre para crearlo de una vez.
  bool get _conductorListo {
    if (!_conductorBuscado) return false;
    if (_conductorEncontrado != null) return !_conductorInactivo;
    return _nombreConductorController.text.trim().length >= 3;
  }

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoSugerido;
    _placaController = TextEditingController(text: ParkingRepository.formatea(widget.placaSugerida));
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _colorController.dispose();
    _modeloController.dispose();
    _documentoController.dispose();
    _nombreConductorController.dispose();
    _correoConductorController.dispose();
    _telefonoConductorController.dispose();
    super.dispose();
  }

  Future<void> _buscarConductor() async {
    final error = Validators.documento(_documentoController.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _buscandoConductor = true;
      _conductorBuscado = false;
      _conductorEncontrado = null;
    });
    try {
      final resultado = await ParkingRepository.instance.buscarConductorPorDocumento(_tipoDocumento, _documentoController.text);
      if (!mounted) return;
      setState(() {
        _conductorEncontrado = resultado;
        _conductorBuscado = true;
        _buscandoConductor = false;
        if (resultado != null) {
          _nombreConductorController.clear();
          _correoConductorController.clear();
          _telefonoConductorController.clear();
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _buscandoConductor = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _cambiarConductor() {
    setState(() {
      _conductorBuscado = false;
      _conductorEncontrado = null;
      _documentoController.clear();
      _nombreConductorController.clear();
      _correoConductorController.clear();
      _telefonoConductorController.clear();
    });
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_conductorBuscado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Busca primero el documento del conductor.')));
      return;
    }
    if (_conductorInactivo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ese conductor está inactivo: no se le puede asociar un vehículo.')));
      return;
    }
    if (!_conductorListo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el nombre completo del conductor nuevo.')));
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final correo = _correoConductorController.text.trim();
      final telefono = _telefonoConductorController.text.trim();
      final vehiculo = await ParkingRepository.instance.registrarVehiculoDesdePortero(
        placa: _placaController.text,
        tipo: _tipo,
        marcaLinea: _marcaController.text.trim(),
        color: _colorController.text.trim(),
        modelo: int.tryParse(_modeloController.text.trim()),
        vehiculoSena: _vehiculoSena,
        conductorId: _conductorEncontrado != null ? _conductorEncontrado!['id'] as int? : null,
        conductorNuevo: _conductorEncontrado == null
            ? {
                'tipo_documento': _tipoDocumento,
                'numero_documento': _documentoController.text.trim(),
                'nombre_apellidos': _nombreConductorController.text.trim(),
                if (correo.isNotEmpty) 'correo': correo,
                if (telefono.isNotEmpty) 'numero_telefonico': telefono,
              }
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vehículo ${ParkingRepository.formatea(vehiculo.placa)} registrado.')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VehicleAuthorizedPage(vehicle: vehiculo)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageTopBar(title: 'Registrar vehículo', subtitle: 'Paso 3 de 3 · Alta en portería', showBack: true, large: false),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DATOS DEL VEHÍCULO', style: AppTextStyles.overline),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 16),
                            Text('Modelo (año) · opcional', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _modeloController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                              decoration: const InputDecoration(hintText: 'Ej. 2022'),
                              validator: Validators.anioVehiculo,
                            ),
                            const SizedBox(height: 12),
                            AppCard(
                              radius: 16,
                              elevated: false,
                              padding: EdgeInsets.zero,
                              child: SettingsTile(
                                icon: Icons.verified_outlined,
                                title: 'Vehículo oficial SENA',
                                value: _vehiculoSena,
                                onChanged: (value) => setState(() => _vehiculoSena = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CONDUCTOR', style: AppTextStyles.overline),
                            const SizedBox(height: 4),
                            Text(
                              'Busca su documento: si ya está registrado se usa esa ficha; si no, completa su nombre para crearla.',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 14),
                            _buildConductorSeccion(),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.dangerDarker),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.dangerDarker))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              BottomActionBar(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _registrar,
                    child: _guardando
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.how_to_reg_rounded, size: 20),
                              SizedBox(width: 10),
                              Flexible(child: Text('Registrar y continuar', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConductorSeccion() {
    if (!_conductorBuscado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128,
                child: DropdownButtonFormField<String>(
                  initialValue: _tipoDocumento,
                  isExpanded: true,
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  items: _tiposDocumento
                      .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$1, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (value) => setState(() => _tipoDocumento = value ?? _tipoDocumento),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  decoration: const InputDecoration(hintText: 'Número de documento'),
                  onFieldSubmitted: (_) => _buscarConductor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _buscandoConductor ? null : _buscarConductor,
              icon: _buscandoConductor
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search_rounded, size: 18),
              label: const Text('Buscar conductor'),
            ),
          ),
        ],
      );
    }

    final encontrado = _conductorEncontrado;
    if (encontrado != null) {
      final nombre = (encontrado['nombre_apellidos'] as String?) ?? '—';
      final documento = '$_tipoDocumento ${_documentoController.text.trim()}';
      final rol = (encontrado['tipo_usuario_nombre'] as String?) ?? 'Conductor';
      if (_conductorInactivo) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_off_rounded, size: 18, color: AppColors.dangerDarker),
                  const SizedBox(width: 8),
                  Expanded(child: Text(nombre, style: AppTextStyles.bodyBold.copyWith(color: AppColors.dangerDarker))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Este conductor está inactivo: no se le puede registrar un vehículo nuevo.',
                style: AppTextStyles.caption.copyWith(color: AppColors.dangerDark),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: _cambiarConductor, child: const Text('Buscar otro documento')),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const IconBadge(icon: Icons.verified_user_rounded, size: 42, iconSize: 20, background: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: AppTextStyles.bodyBold.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      StatusChip(label: rol, tone: ChipTone.info, showDot: false),
                      const SizedBox(width: 8),
                      Flexible(child: Text(documento, style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(onPressed: _cambiarConductor, child: const Text('Cambiar')),
          ],
        ),
      );
    }

    // Documento sin ficha: se completa el nombre para crear al conductor al
    // registrar el vehículo (misma llamada, `POST /vehiculos` con `conductor`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warningDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No hay ningún conductor con $_tipoDocumento ${_documentoController.text.trim()}. Completa su nombre para crearlo.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.warningDark, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Nombre completo', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nombreConductorController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre y apellidos'),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            final texto = (value ?? '').trim();
            if (texto.isEmpty) return 'Ingresa el nombre del conductor';
            if (texto.length < 3) return 'Nombre demasiado corto';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Text('Correo · opcional', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _correoConductorController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
          validator: (value) => (value == null || value.trim().isEmpty) ? null : Validators.correo(value),
        ),
        const SizedBox(height: 12),
        Text('Teléfono · opcional', style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: _telefonoConductorController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: const InputDecoration(hintText: '3001234567'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _cambiarConductor, child: const Text('Buscar otro documento')),
      ],
    );
  }
}

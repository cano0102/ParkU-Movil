import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController(text: 'aarboleda@sena.edu.co');
  final _claveController = TextEditingController();
  bool _ocultarClave = true;
  bool _cargando = false;
  bool _esConductor = false;

  @override
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  void _elegirRol(bool esConductor) {
    setState(() {
      _esConductor = esConductor;
      _correoController.text = esConductor ? ParkingRepository.instance.conductorCorreo : ParkingRepository.instance.guardaCorreo;
    });
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _cargando = false);
    Navigator.of(context).pushNamedAndRemoveUntil(_esConductor ? AppRoutes.driverHome : AppRoutes.home, (route) => false);
  }

  void _recuperarClave() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: const Text('Contacta a soporte SENA para restablecer tu contraseña institucional.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sede = ParkingRepository.instance.sede;
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', width: 72, height: 70, fit: BoxFit.contain),
                  const SizedBox(height: 14),
                  Text('ParkU', style: AppTextStyles.heading1),
                  const SizedBox(height: 6),
                  Text(
                    'Control de acceso vehicular\n$sede',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),

                  Text('Ingresas como', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _RolOpcion(icono: Icons.security, etiqueta: 'Guarda', seleccionado: !_esConductor, onTap: () => _elegirRol(false))),
                      const SizedBox(width: 10),
                      Expanded(child: _RolOpcion(icono: Icons.directions_car, etiqueta: 'Conductor', seleccionado: _esConductor, onTap: () => _elegirRol(true))),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Text('Correo institucional', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.textPlaceholder),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Ingresa tu correo institucional';
                      if (!value.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  Text('Contraseña', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _claveController,
                    obscureText: _ocultarClave,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarClave ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textPlaceholder,
                        ),
                        onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ingresar'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _recuperarClave,
                      child: Text('¿Olvidaste tu contraseña?', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primaryDark)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'SENA · Servicio Nacional de Aprendizaje',
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RolOpcion extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _RolOpcion({required this.icono, required this.etiqueta, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: seleccionado ? null : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 20, color: seleccionado ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                etiqueta,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: seleccionado ? Colors.white : AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

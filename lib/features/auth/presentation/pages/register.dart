import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/session_repository.dart';
import '../../../../core/network/api_exception.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _ocultarClave = true;
  bool _ocultarConfirmar = true;
  bool _cargando = false;
  bool _aceptaTerminos = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _documentoController.dispose();
    _claveController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);

    try {
      await SessionRepository.instance.registrar(
        nombre: _nombreController.text.trim(),
        correo: _correoController.text.trim(),
        documento: _documentoController.text.trim(),
        contrasena: _claveController.text,
      );

      if (!mounted) return;

      // Registro exitoso → volver al login con mensaje.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Ya puedes iniciar sesión.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const alturaCabecera = 250.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Fondo verde de la parte superior.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: alturaCabecera + topInset,
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(right: -70, top: -60, child: _circle(220)),
                    Positioned(left: -40, bottom: -60, child: _circle(160)),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón de volver.
                    SizedBox(
                      height: 42,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BackCircleButton(
                          color: Colors.white,
                          background: Colors.white.withValues(alpha: 0.16),
                          borderColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.png', width: 44, height: 44, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Crear cuenta',
                                style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 28, height: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Regístrate en ParkU',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      radius: 28,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Datos personales', style: AppTextStyles.heading3),
                            const SizedBox(height: 4),
                            Text(
                              'Completa la información para registrarte.',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 22),

                            // Nombre completo
                            Text('Nombre completo', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nombreController,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'Juan Pérez',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textPlaceholder),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                                if (v.trim().length < 3) return 'Nombre demasiado corto';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Documento
                            Text('Documento', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _documentoController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: '1234567890',
                                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textPlaceholder),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa tu documento';
                                if (v.trim().length < 6) return 'Documento inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Correo
                            Text('Correo institucional', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                hintText: 'nombre@sena.edu.co',
                                prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textPlaceholder),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                                final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                                if (!regex.hasMatch(v.trim())) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Contraseña
                            Text('Contraseña', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _claveController,
                              obscureText: _ocultarClave,
                              textInputAction: TextInputAction.next,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textPlaceholder),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _ocultarClave ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textPlaceholder,
                                  ),
                                  onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirmar contraseña
                            Text('Confirmar contraseña', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmarController,
                              obscureText: _ocultarConfirmar,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _cargando ? null : _registrar(),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textPlaceholder),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _ocultarConfirmar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textPlaceholder,
                                  ),
                                  onPressed: () => setState(() => _ocultarConfirmar = !_ocultarConfirmar),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                                if (v != _claveController.text) return 'Las contraseñas no coinciden';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Términos y condiciones
                            Row(
                              children: [
                                Checkbox(
                                  value: _aceptaTerminos,
                                  onChanged: _cargando
                                      ? null
                                      : (v) => setState(() => _aceptaTerminos = v ?? false),
                                  activeColor: AppColors.primary,
                                ),
                                Expanded(
                                  child: Text(
                                    'Acepto los términos y condiciones',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Botón registrar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrar,
                                child: _cargando
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                )
                                    : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Crear cuenta'),
                                    SizedBox(width: 8),
                                    Icon(Icons.check_rounded, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Volver a iniciar sesión
                            Center(
                              child: TextButton(
                                onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
          ],
        ),
      ),
    );
  }

  Widget _circle(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
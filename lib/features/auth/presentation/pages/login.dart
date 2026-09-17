import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/data/session_repository.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../widgets/server_config_dialog.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  bool _ocultarClave = true;
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    try {
      await SessionRepository.instance.iniciarSesion(
        correo: _correoController.text.trim(),
        contrasena: _claveController.text,
      );
      await ParkingRepository.instance.iniciar();
      if (!mounted) return;
      final esConductor = SessionRepository.instance.esConductor;
      Navigator.of(context).pushNamedAndRemoveUntil(esConductor ? AppRoutes.driverHome : AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Sin código de estado la API ni siquiera respondió: se ofrece de una
      // vez cambiar la dirección del servidor, que es el arreglo habitual.
      final sinRespuesta = e.statusCode == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: Duration(seconds: sinRespuesta ? 8 : 4),
          action: sinRespuesta ? SnackBarAction(label: 'Configurar', onPressed: _configurarServidor) : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _recuperarClave() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
  }

  Future<void> _configurarServidor() async {
    final cambio = await ServerConfigDialog.mostrar(context);
    if (!mounted) return;
    if (cambio) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Servidor: ${ApiConfig.baseUrl}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final puedeVolver = Navigator.of(context).canPop();
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
                    SizedBox(
                      height: 42,
                      child: puedeVolver
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: BackCircleButton(
                                color: Colors.white,
                                background: Colors.white.withValues(alpha: 0.16),
                                borderColor: Colors.white.withValues(alpha: 0.25),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))],
                          ),
                          child: Image.asset('assets/images/logo.png', width: 44, height: 44, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ParkU', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 30, height: 1)),
                              const SizedBox(height: 4),
                              Text(
                                'Control de acceso vehicular',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w600),
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
                            Text('Iniciar sesión', style: AppTextStyles.heading3),
                            const SizedBox(height: 4),
                            Text(
                              'Usa tu cuenta institucional para continuar.',
                              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 22),
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
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Ingresa tu correo institucional';
                                if (!value.contains('@')) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Text('Contraseña', style: AppTextStyles.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _claveController,
                              obscureText: _ocultarClave,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _cargando ? null : _ingresar(),
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
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _recuperarClave,
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Text('SENA · Servicio Nacional de Aprendizaje', style: AppTextStyles.small, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        onPressed: _configurarServidor,
                        style: TextButton.styleFrom(foregroundColor: AppColors.textPlaceholder),
                        icon: const Icon(Icons.dns_outlined, size: 16),
                        label: Text(
                          'Servidor: ${ApiConfig.descripcion}',
                          style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

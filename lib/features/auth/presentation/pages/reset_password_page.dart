import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/session_repository.dart';
import '../../../../core/network/api_exception.dart';

/// Segundo paso del flujo de recuperación de contraseña (HU 02.2.8): se
/// pega el token recibido por correo y se fija la nueva contraseña.
class ResetPasswordPage extends StatefulWidget {
  final String? correo;

  const ResetPasswordPage({super.key, this.correo});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _claveController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _ocultarClave = true;
  bool _cargando = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _claveController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    try {
      await SessionRepository.instance.restablecerContrasena(
        token: _tokenController.text.trim(),
        nuevaContrasena: _claveController.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.settings.name == AppRoutes.login);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Ya puedes iniciar sesión.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackCircleButton(),
              const SizedBox(height: 22),
              const IconBadge(icon: Icons.password_rounded, size: 56, iconSize: 28),
              const SizedBox(height: 18),
              Text('Restablecer contraseña', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text(
                widget.correo != null && widget.correo!.isNotEmpty
                    ? 'Copia el código del correo que enviamos a ${widget.correo} y elige tu nueva contraseña.'
                    : 'Copia el código que recibiste por correo y elige tu nueva contraseña.',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, height: 1.4),
              ),
              const SizedBox(height: 26),
              AppCard(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                radius: 24,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Código de recuperación', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tokenController,
                        autocorrect: false,
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'Pega aquí el código del correo',
                          prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.textPlaceholder),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa el código recibido';
                          if (value.trim().length < 32) return 'El código no parece completo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Nueva contraseña', style: AppTextStyles.label),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa la nueva contraseña';
                          if (value.length < 8) return 'Debe tener al menos 8 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Confirmar contraseña', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmarController,
                        obscureText: _ocultarClave,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _cargando ? null : _restablecer(),
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, letterSpacing: 2),
                        decoration: const InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textPlaceholder),
                        ),
                        validator: (value) {
                          if (value != _claveController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _restablecer,
                          child: _cargando
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('Restablecer contraseña'),
                        ),
                      ),
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
}

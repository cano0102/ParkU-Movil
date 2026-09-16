import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/session_repository.dart';
import '../../../../core/network/api_exception.dart';
import 'reset_password_page.dart';

/// Primer paso del flujo de recuperación de contraseña (HU 02.2.7): se pide
/// el correo institucional y, si existe, la API envía un enlace con un
/// token de recuperación válido por una hora.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    try {
      await SessionRepository.instance.solicitarRecuperacion(correo: _correoController.text.trim());
      if (!mounted) return;
      setState(() => _enviado = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irARestablecer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResetPasswordPage(correo: _correoController.text.trim())),
    );
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
              IconBadge(
                icon: _enviado ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
                size: 56,
                iconSize: 28,
              ),
              const SizedBox(height: 18),
              Text(_enviado ? 'Revisa tu correo' : 'Recuperar contraseña', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text(
                _enviado
                    ? 'Si el correo está registrado, te enviamos un enlace con un código de recuperación válido por 1 hora.'
                    : 'Ingresa tu correo institucional y te enviaremos instrucciones para restablecer tu contraseña.',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, height: 1.4),
              ),
              const SizedBox(height: 26),
              if (!_enviado) ...[
                AppCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                  radius: 24,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Correo institucional', style: AppTextStyles.label),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _cargando ? null : _enviar(),
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _enviar,
                            child: _cargando
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                                : const Text('Enviar instrucciones'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _irARestablecer,
                    icon: const Icon(Icons.vpn_key_rounded, size: 18),
                    label: const Text('Ya tengo mi código'),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _enviado = false),
                    child: const Text('Usar otro correo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

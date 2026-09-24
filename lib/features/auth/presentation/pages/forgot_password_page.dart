import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/session_repository.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import 'reset_password_page.dart';

/// Tipos de documento que acepta la API (`verificarIdentidadValidation` en
/// Api-ParkU): mismo catálogo que usa portería al registrar un conductor.
const List<(String, String)> _tiposDocumento = [
  ('CC', 'Cédula de ciudadanía'),
  ('CE', 'Cédula de extranjería'),
  ('TI', 'Tarjeta de identidad'),
  ('PASAPORTE', 'Pasaporte'),
  ('PEP', 'Permiso especial de permanencia'),
  ('NIT', 'NIT'),
];

/// Flujo de recuperación de contraseña: la API ya no envía correos, así que
/// se verifica la identidad con datos que ya tiene el sistema (correo,
/// documento y nombre — `POST /api/auth/verificar-identidad`). Si coinciden
/// con una cuenta, la API entrega el token de recuperación en la misma
/// respuesta y se pasa directo a [ResetPasswordPage] con él.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _documentoController = TextEditingController();
  String _tipoDocumento = 'CC';
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _nombreController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _verificar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);
    try {
      final token = await SessionRepository.instance.verificarIdentidad(
        correo: _correoController.text.trim(),
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _documentoController.text.trim(),
        nombre: _nombreController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResetPasswordPage(token: token)),
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
              const IconBadge(icon: Icons.lock_reset_rounded, size: 56, iconSize: 28),
              const SizedBox(height: 18),
              Text('Recuperar contraseña', style: AppTextStyles.heading2),
              const SizedBox(height: 6),
              Text(
                'Confirma tus datos y podrás crear una contraseña nueva de '
                'inmediato, sin esperar ningún correo.',
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
                        validator: Validators.correo,
                      ),
                      const SizedBox(height: 16),
                      Text('Nombre completo', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'Como aparece en tu cuenta',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textPlaceholder),
                        ),
                        validator: (v) => Validators.requerido(v, 'tu nombre'),
                      ),
                      const SizedBox(height: 16),
                      Text('Documento', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 118,
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
                              textInputAction: TextInputAction.done,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                              onFieldSubmitted: (_) => _cargando ? null : _verificar(),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(hintText: '1234567890'),
                              validator: Validators.documento,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _verificar,
                          child: _cargando
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('Verificar identidad'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _cargando ? null : () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                  ),
                  child: const Text('Ya tengo un código de recuperación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

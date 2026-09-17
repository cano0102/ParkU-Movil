import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/network/api_config.dart';

/// Diálogo para cambiar la dirección de Api-ParkU sin recompilar: en un
/// celular físico la app no puede llegar a `localhost`/`10.0.2.2` del
/// computador y hay que apuntarla a la IP del PC en la red Wi-Fi.
///
/// Devuelve `true` si la dirección cambió.
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<bool> mostrar(BuildContext context) async {
    final cambio = await showDialog<bool>(context: context, builder: (_) => const ServerConfigDialog());
    return cambio ?? false;
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _urlController = TextEditingController(text: ApiConfig.baseUrl);
  bool _probando = false;
  bool _guardando = false;
  String? _resultado;
  bool _resultadoOk = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _usar(String url) {
    _urlController.text = url;
    setState(() => _resultado = null);
    _probar();
  }

  Future<void> _probar() async {
    setState(() {
      _probando = true;
      _resultado = null;
    });
    final error = await ApiConfig.probar(_urlController.text);
    if (!mounted) return;
    setState(() {
      _probando = false;
      _resultadoOk = error == null;
      _resultado = error ?? 'Conexión correcta con ${ApiConfig.normalizar(_urlController.text)}';
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final anterior = ApiConfig.baseUrl;
    final nueva = await ApiConfig.guardar(_urlController.text);
    if (!mounted) return;
    Navigator.of(context).pop(nueva != anterior);
  }

  Future<void> _restablecer() async {
    final anterior = ApiConfig.baseUrl;
    await ApiConfig.guardar(null);
    if (!mounted) return;
    _urlController.text = ApiConfig.baseUrl;
    setState(() {
      _resultado = null;
    });
    if (ApiConfig.baseUrl != anterior) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Row(
        children: [
          const Icon(Icons.dns_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Servidor de ParkU', style: AppTextStyles.heading3)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dirección de Api-ParkU. En el emulador de Android usa 10.0.2.2; '
              'en un celular físico, la IP de tu computador en la red Wi-Fi '
              '(p. ej. 192.168.1.10:3000) o la API en la nube.',
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Atajo(label: 'Emulador', url: 'http://10.0.2.2:3000/api', onTap: _usar),
                _Atajo(label: 'Este PC', url: 'http://localhost:3000/api', onTap: _usar),
                _Atajo(label: 'Nube (Render)', url: ApiConfig.nube, onTap: _usar),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:3000/api',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.textPlaceholder),
              ),
              onChanged: (_) => setState(() => _resultado = null),
              onSubmitted: (_) => _probar(),
            ),
            const SizedBox(height: 6),
            Text(
              'Ahora: ${ApiConfig.baseUrl}${ApiConfig.usandoRespaldo ? ' (respaldo automático: la local no respondió)' : ''}',
              style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder),
            ),
            if (_resultado != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_resultadoOk ? AppColors.primary : AppColors.danger).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _resultadoOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 18,
                      color: _resultadoOk ? AppColors.primary : AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resultado!,
                        style: AppTextStyles.caption.copyWith(
                          color: _resultadoOk ? AppColors.primaryDark : AppColors.danger,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _probando ? null : _probar,
                  icon: _probando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: const Text('Probar conexión'),
                ),
                const Spacer(),
                if (ApiConfig.esPersonalizada) TextButton(onPressed: _restablecer, child: const Text('Restablecer')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardando ? null : _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

class _Atajo extends StatelessWidget {
  final String label;
  final String url;
  final ValueChanged<String> onTap;

  const _Atajo({required this.label, required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
      ),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.primarySoftBorder),
      visualDensity: VisualDensity.compact,
      onPressed: () => onTap(url),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import 'confirm_plate_page.dart';

/// Placas usadas para simular la lectura automática de la cámara mientras
/// no exista un motor de reconocimiento óptico (OCR) conectado. El guarda
/// siempre puede corregir el texto detectado antes de continuar, tal como
/// contempla el diseño ("Toca la placa para corregir...").
const _placasSimuladas = ['WGY482', 'TQP71D', 'JKD09E', 'HRT340', 'MTG18C'];

class ScanPlatePage extends StatefulWidget {
  const ScanPlatePage({super.key});

  @override
  State<ScanPlatePage> createState() => _ScanPlatePageState();
}

class _ScanPlatePageState extends State<ScanPlatePage> with SingleTickerProviderStateMixin {
  bool _flashOn = false;
  bool _capturando = false;
  late final AnimationController _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  Future<void> _capturar() async {
    if (_capturando) return;
    setState(() => _capturando = true);
    await Future.delayed(const Duration(milliseconds: 450));
    final placaDetectada = _placasSimuladas[Random().nextInt(_placasSimuladas.length)];
    if (!mounted) return;
    setState(() => _capturando = false);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfirmPlatePage(placaDetectada: placaDetectada)));
  }

  Future<void> _digitarManual() async {
    final controller = TextEditingController();
    final placa = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digitar placa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: AppTextStyles.plate(size: 18),
          decoration: const InputDecoration(hintText: 'Ej. WGY482'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Continuar')),
        ],
      ),
    );
    if (placa == null || placa.trim().isEmpty) return;
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfirmPlatePage(placaDetectada: ParkingRepository.normaliza(placa))));
  }

  @override
  Widget build(BuildContext context) {
    final frameWidth = (MediaQuery.sizeOf(context).width - 68).clamp(220.0, 380.0).toDouble();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // "Vista de cámara": mientras no hay cámara real, un fondo con un
            // degradado radial que imita el viñeteado del visor.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.1, colors: [Color(0xFF1B2533), Color(0xFF0B1220)]),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        GlassIconButton(icon: Icons.close_rounded, size: 42, onTap: () => Navigator.of(context).pop()),
                        const Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Escanear placa',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Paso 1 de 3',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                        GlassIconButton(icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, size: 42, onTap: () => setState(() => _flashOn = !_flashOn)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VISTA DE CÁMARA EN VIVO',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: frameWidth,
                            height: 160,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                    ),
                                  ),
                                ),
                                _corner(Alignment.topLeft),
                                _corner(Alignment.topRight),
                                _corner(Alignment.bottomLeft),
                                _corner(Alignment.bottomRight),
                                AnimatedBuilder(
                                  animation: _scanAnim,
                                  builder: (context, child) {
                                    return Positioned(
                                      left: 14,
                                      right: 14,
                                      top: 10 + _scanAnim.value * 138,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)],
                                          gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0), AppColors.primaryAccent, AppColors.primary.withValues(alpha: 0)]),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    child: Text(
                      'Encuadra la placa dentro del marco.\nLa lectura se confirma sola al estabilizarse.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13, fontWeight: FontWeight.w600, height: 1.45),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 26, top: 8),
                    child: Column(
                      children: [
                        _CaptureButton(capturando: _capturando, onTap: _capturar),
                        const SizedBox(height: 18),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: _digitarManual,
                            borderRadius: BorderRadius.circular(999),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.keyboard_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Digitar placa manualmente',
                                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    const side = BorderSide(color: AppColors.primary, width: 4);
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(top: isTop ? side : BorderSide.none, bottom: !isTop ? side : BorderSide.none, left: isLeft ? side : BorderSide.none, right: !isLeft ? side : BorderSide.none),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(22) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(22) : Radius.zero,
            bottomLeft: !isTop && isLeft ? const Radius.circular(22) : Radius.zero,
            bottomRight: !isTop && !isLeft ? const Radius.circular(22) : Radius.zero,
          ),
        ),
      ),
    );
  }
}

/// Botón de captura estilo obturador: anillo blanco translúcido con el
/// disco verde en el centro.
class _CaptureButton extends StatelessWidget {
  final bool capturando;
  final VoidCallback onTap;

  const _CaptureButton({required this.capturando, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 82,
        height: 82,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 3),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient, boxShadow: AppColors.primaryShadow),
          child: capturando
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                )
              : const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

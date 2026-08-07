import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConfirmPlatePage(placaDetectada: placaDetectada)),
    );
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
          decoration: const InputDecoration(hintText: 'Ej. WGY482'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (placa == null || placa.trim().isEmpty) return;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmPlatePage(placaDetectada: ParkingRepository.normaliza(placa)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF0B1220),
            alignment: Alignment.center,
            child: Text(
              'VISTA DE CÁMARA EN VIVO\n[ video del vehículo ]',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.28), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundGlassButton(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                      const Text('Escanear placa', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                      _RoundGlassButton(
                        icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () => setState(() => _flashOn = !_flashOn),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 322,
                      height: 150,
                      child: Stack(
                        children: [
                          _corner(Alignment.topLeft),
                          _corner(Alignment.topRight),
                          _corner(Alignment.bottomLeft),
                          _corner(Alignment.bottomRight),
                          AnimatedBuilder(
                            animation: _scanAnim,
                            builder: (context, child) {
                              return Positioned(
                                left: 10,
                                right: 10,
                                top: 8 + _scanAnim.value * 134,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      AppColors.primary.withValues(alpha: 0),
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                  child: Text(
                    'Encuadra la placa dentro del marco.\nLa lectura se confirma sola al estabilizarse.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 6),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _capturar,
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 5),
                            ),
                            child: _capturando
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                                  )
                                : const Icon(Icons.photo_camera, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: _digitarManual,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Digitar placa manualmente', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            ],
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
    );
  }

  Widget _corner(Alignment alignment) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;
    return Align(
      alignment: alignment,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.primary, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _RoundGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundGlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/data/session_repository.dart';

/// Introducción de ParkU: continúa el splash nativo (mismo verde y logo)
/// con una animación corta de marca y, mientras tanto, verifica contra
/// Api-ParkU si hay una sesión guardada para decidir a dónde entrar:
///
/// - sesión de conductor → inicio del conductor
/// - sesión de vigilante/admin → inicio de portería
/// - sin sesión o token vencido → bienvenida
///
/// Si la API no responde, no se borra el token guardado: se entra por la
/// bienvenida y en el próximo arranque se vuelve a intentar.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  /// Tiempo mínimo en pantalla para que la animación se vea completa
  /// aunque la API responda al instante.
  static const _duracionMinima = Duration(milliseconds: 2200);

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  late final Animation<double> _logoScale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack));
  late final Animation<double> _logoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));
  late final Animation<double> _textoFade = CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.easeOut));
  late final Animation<Offset> _textoSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _pieFade = CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut));

  final _temporizadores = <Timer>{};
  String _estado = 'Verificando sesión…';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _arrancar();
  }

  @override
  void dispose() {
    for (final t in _temporizadores) {
      t.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Como Future.delayed, pero cancelable: si la pantalla se desecha antes
  /// (p. ej. en pruebas), el temporizador no queda pendiente y la espera
  /// simplemente nunca se cumple.
  Future<void> _esperar(Duration duracion) {
    final completer = Completer<void>();
    _temporizadores.add(Timer(duracion, completer.complete));
    return completer.future;
  }

  Future<void> _arrancar() async {
    final espera = _esperar(_duracionMinima);
    var destino = AppRoutes.welcome;
    try {
      final session = SessionRepository.instance;
      final resultado = await session.restaurar();
      switch (resultado) {
        case EstadoSesion.restaurada:
          _actualizarEstado('Cargando tu parqueadero…');
          await ParkingRepository.instance.iniciar();
          destino = session.esConductor ? AppRoutes.driverHome : AppRoutes.home;
        case EstadoSesion.sinConexion:
          _actualizarEstado('Sin conexión con el servidor');
          // Deja leer el aviso antes de pasar a la bienvenida.
          await _esperar(const Duration(milliseconds: 1200));
        case EstadoSesion.sinSesion:
          break;
      }
    } catch (_) {
      // Cualquier fallo inesperado al arrancar no debe dejar la app
      // atascada en la introducción: se entra por la bienvenida.
      destino = AppRoutes.welcome;
    }
    await espera;
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _estado = 'Listo';
    });
    Navigator.of(context).pushAndRemoveUntil(AppRouter.fadeRoute(destino), (route) => false);
  }

  void _actualizarEstado(String texto) {
    if (mounted) setState(() => _estado = texto);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(right: -90, top: -60, child: _burbuja(260)),
              Positioned(left: -70, top: 220, child: _burbuja(180)),
              Positioned(right: 30, bottom: 140, child: _burbuja(90)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 28, offset: Offset(0, 12))],
                          ),
                          child: Image.asset('assets/images/logo.png', width: 76, height: 76, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: _textoFade,
                      child: SlideTransition(
                        position: _textoSlide,
                        child: Column(
                          children: [
                            Text('ParkU', style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 40, height: 1)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Text(
                                'CONTROL DE ACCESO VEHICULAR',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 40 + bottomInset,
                child: FadeTransition(
                  opacity: _pieFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _cargando ? null : 1,
                            minHeight: 4,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _estado,
                          key: ValueKey(_estado),
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'SENA · Servicio Nacional de Aprendizaje',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _burbuja(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

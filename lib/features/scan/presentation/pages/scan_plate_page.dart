import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/plate_reader.dart';
import 'confirm_plate_page.dart';

/// Escáner de placas con la cámara del dispositivo.
///
/// Muestra la vista previa en vivo y va pasando fotogramas por el OCR de
/// ML Kit (en el dispositivo, sin internet). Cuando la misma placa se lee dos
/// veces seguidas se da por buena y se pasa a confirmarla; el botón de
/// captura fuerza una lectura con la última placa vista (o con una foto), y
/// "Digitar placa manualmente" sigue disponible para cuando la cámara no
/// ayuda (placa sucia, de noche, permiso denegado, emulador...).
class ScanPlatePage extends StatefulWidget {
  const ScanPlatePage({super.key});

  @override
  State<ScanPlatePage> createState() => _ScanPlatePageState();
}

class _ScanPlatePageState extends State<ScanPlatePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _intervaloLectura = Duration(milliseconds: 600);

  /// Lecturas seguidas iguales necesarias para confirmar sola la placa.
  static const _lecturasParaConfirmar = 2;

  bool _flashOn = false;
  bool _capturando = false;
  late final AnimationController _scanAnim;

  CameraController? _camara;
  CameraDescription? _descripcion;
  bool _iniciandoCamara = true;

  /// La cámara estaba abierta cuando la app pasó a segundo plano: hay que
  /// reabrirla al volver (el controlador anterior ya se liberó).
  bool _suspendida = false;

  /// Motivo por el que no hay vista previa (permiso denegado, sin cámara,
  /// plataforma sin soporte...). Con esto la pantalla ofrece solo la entrada
  /// manual en vez de quedarse en negro.
  String? _sinCamara;
  bool _permisoDenegado = false;

  final TextRecognizer _ocr = TextRecognizer(script: TextRecognitionScript.latin);
  bool _procesando = false;
  DateTime _ultimoProcesado = DateTime.fromMillisecondsSinceEpoch(0);
  String? _ultimaLectura;
  int _lecturasIguales = 0;
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _iniciarCamara();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanAnim.dispose();
    _detenerCamara();
    // En plataformas sin ML Kit (pruebas, escritorio) cerrar lanza; no hay
    // nada que hacer con ese error.
    _ocr.close().catchError((_) {});
    super.dispose();
  }

  /// La cámara no puede seguir abierta con la app en segundo plano (Android
  /// la cierra y el controlador queda inválido): se suelta al salir y se
  /// vuelve a abrir al regresar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_camara == null) return;
      _suspendida = true;
      _detenerCamara();
    } else if (state == AppLifecycleState.resumed && _suspendida) {
      _suspendida = false;
      _iniciarCamara();
    }
  }

  Future<void> _iniciarCamara() async {
    if (!mounted) return;
    setState(() {
      _iniciandoCamara = true;
      _sinCamara = null;
      _permisoDenegado = false;
    });
    try {
      final camaras = await availableCameras();
      if (camaras.isEmpty) throw StateError('sin cámara');
      _descripcion = camaras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => camaras.first);

      final controller = CameraController(
        _descripcion!,
        ResolutionPreset.high,
        enableAudio: false,
        // ML Kit lee NV21 en Android y BGRA en iOS directamente desde el
        // fotograma, sin convertir nada por software.
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camara = controller;
      if (_flashOn) await _aplicarFlash();
      await controller.startImageStream(_onFotograma);
      setState(() => _iniciandoCamara = false);
    } on CameraException catch (e) {
      if (!mounted) return;
      final denegado = e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt' || e.code == 'CameraAccessRestricted';
      setState(() {
        _iniciandoCamara = false;
        _permisoDenegado = denegado;
        _sinCamara = denegado
            ? 'ParkU no tiene permiso para usar la cámara. Actívalo en los ajustes del teléfono o digita la placa.'
            : 'No se pudo abrir la cámara (${e.description ?? e.code}). Digita la placa manualmente.';
      });
    } catch (_) {
      // Sin cámara (emulador, escritorio, web sin soporte) o plugin ausente en
      // pruebas: se sigue con la entrada manual.
      if (!mounted) return;
      setState(() {
        _iniciandoCamara = false;
        _sinCamara = 'Este dispositivo no tiene cámara disponible. Digita la placa manualmente.';
      });
    }
  }

  Future<void> _detenerCamara() async {
    final controller = _camara;
    _camara = null;
    if (controller == null) return;
    // Sin esto la pantalla seguiría pintando la vista previa de un
    // controlador liberado (se ve negra).
    if (mounted) setState(() {});
    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
    } catch (_) {}
    await controller.dispose();
  }

  Future<void> _aplicarFlash() async {
    final controller = _camara;
    if (controller == null) return;
    try {
      await controller.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      // Sin linterna (cámara frontal, emulador): el botón no hace nada.
    }
  }

  void _alternarFlash() {
    setState(() => _flashOn = !_flashOn);
    _aplicarFlash();
  }

  // ------------------------------------------------------------------
  // OCR sobre los fotogramas
  // ------------------------------------------------------------------

  Future<void> _onFotograma(CameraImage imagen) async {
    if (_procesando || _navegando) return;
    final ahora = DateTime.now();
    if (ahora.difference(_ultimoProcesado) < _intervaloLectura) return;
    _ultimoProcesado = ahora;
    _procesando = true;
    try {
      final entrada = _inputImageDe(imagen);
      if (entrada == null) return;
      final texto = await _ocr.processImage(entrada);
      if (!mounted || _navegando) return;
      final placa = PlateReader.extraer(texto.text);
      _registrarLectura(placa);
    } catch (_) {
      // Un fotograma que no se pudo leer no importa: viene otro enseguida.
    } finally {
      _procesando = false;
    }
  }

  /// Dos lecturas seguidas iguales confirman la placa. Una lectura distinta
  /// reinicia la cuenta; un fotograma sin placa no la borra (para que el
  /// texto en pantalla no parpadee) pero tampoco suma.
  void _registrarLectura(String? placa) {
    if (placa == null) return;
    if (placa == _ultimaLectura) {
      _lecturasIguales++;
    } else {
      _ultimaLectura = placa;
      _lecturasIguales = 1;
    }
    if (mounted) setState(() {});
    if (_lecturasIguales >= _lecturasParaConfirmar) _confirmar(placa);
  }

  /// Convierte el fotograma de la cámara al formato que espera ML Kit, con la
  /// rotación correcta según la orientación del sensor y del teléfono
  /// (según el ejemplo oficial de google_mlkit).
  InputImage? _inputImageDe(CameraImage imagen) {
    final controller = _camara;
    final descripcion = _descripcion;
    if (controller == null || descripcion == null) return null;

    final sensorOrientation = descripcion.sensorOrientation;
    InputImageRotation? rotacion;
    if (Platform.isIOS) {
      rotacion = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var compensacion = _orientaciones[controller.value.deviceOrientation];
      if (compensacion == null) return null;
      if (descripcion.lensDirection == CameraLensDirection.front) {
        compensacion = (sensorOrientation + compensacion) % 360;
      } else {
        compensacion = (sensorOrientation - compensacion + 360) % 360;
      }
      rotacion = InputImageRotationValue.fromRawValue(compensacion);
    }
    if (rotacion == null) return null;

    final formato = InputImageFormatValue.fromRawValue(imagen.format.raw);
    if (formato == null) return null;
    if (Platform.isAndroid && formato != InputImageFormat.nv21) return null;
    if (Platform.isIOS && formato != InputImageFormat.bgra8888) return null;
    if (imagen.planes.length != 1) return null;

    final plano = imagen.planes.first;
    return InputImage.fromBytes(
      bytes: plano.bytes,
      metadata: InputImageMetadata(
        size: Size(imagen.width.toDouble(), imagen.height.toDouble()),
        rotation: rotacion,
        format: formato,
        bytesPerRow: plano.bytesPerRow,
      ),
    );
  }

  static const _orientaciones = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // ------------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------------

  Future<void> _confirmar(String placa) async {
    if (_navegando) return;
    _navegando = true;
    await _detenerCamara();
    if (!mounted) return;
    setState(() => _capturando = false);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfirmPlatePage(placaDetectada: placa)));
    // Al volver (p. ej. "Repetir") se reanuda la lectura desde cero.
    if (!mounted) return;
    _navegando = false;
    _ultimaLectura = null;
    _lecturasIguales = 0;
    _iniciarCamara();
  }

  /// Botón de captura: usa la última placa vista; si aún no hay ninguna, toma
  /// una foto y la pasa por el OCR (a veces la foto fija, con enfoque, lee lo
  /// que el fotograma en movimiento no).
  Future<void> _capturar() async {
    if (_capturando || _navegando) return;
    final vista = _ultimaLectura;
    if (vista != null) {
      _confirmar(vista);
      return;
    }
    final controller = _camara;
    if (controller == null) {
      _digitarManual();
      return;
    }
    setState(() => _capturando = true);
    try {
      if (controller.value.isStreamingImages) await controller.stopImageStream();
      final foto = await controller.takePicture();
      final texto = await _ocr.processImage(InputImage.fromFilePath(foto.path));
      final placa = PlateReader.extraer(texto.text);
      if (!mounted) return;
      if (placa != null) {
        _confirmar(placa);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se reconoció una placa. Acércate un poco más o digítala manualmente.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo tomar la foto. Intenta de nuevo.')));
    } finally {
      if (mounted && !_navegando) {
        setState(() => _capturando = false);
        final c = _camara;
        if (c != null && c.value.isInitialized && !c.value.isStreamingImages) {
          try {
            await c.startImageStream(_onFotograma);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _digitarManual() async {
    final controller = TextEditingController();
    final placa = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final error = Validators.placaCualquierTipo(controller.text);
          return AlertDialog(
            title: const Text('Digitar placa'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: AppTextStyles.plate(size: 18),
              decoration: InputDecoration(hintText: 'Ej. WGY482', errorText: error, counterText: ''),
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(onPressed: error == null ? () => Navigator.pop(ctx, controller.text) : null, child: const Text('Continuar')),
            ],
          );
        },
      ),
    );
    if (placa == null || placa.trim().isEmpty) return;
    if (!mounted) return;
    _confirmar(ParkingRepository.normaliza(placa));
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final frameWidth = (MediaQuery.sizeOf(context).width - 68).clamp(220.0, 380.0).toDouble();
    final camara = _camara;
    final hayVista = camara != null && camara.value.isInitialized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (hayVista)
              _VistaPrevia(controller: camara)
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.1, colors: [Color(0xFF1B2533), Color(0xFF0B1220)]),
                ),
              ),
            // Oscurece un poco alrededor del marco para que la placa resalte.
            if (hayVista) Container(color: Colors.black.withValues(alpha: 0.25)),
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
                        GlassIconButton(
                          icon: _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          size: 42,
                          onTap: hayVista ? _alternarFlash : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _iniciandoCamara
                                ? 'ABRIENDO CÁMARA…'
                                : hayVista
                                ? 'VISTA DE CÁMARA EN VIVO'
                                : 'CÁMARA NO DISPONIBLE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
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
                                if (hayVista)
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
                                            boxShadow: [
                                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1),
                                            ],
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.primary.withValues(alpha: 0),
                                                AppColors.primaryAccent,
                                                AppColors.primary.withValues(alpha: 0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                if (_ultimaLectura != null)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'Leyendo ${ParkingRepository.formatea(_ultimaLectura!)}',
                                          style: AppTextStyles.mono(size: 13, color: AppColors.primaryAccent),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_sinCamara != null) ...[
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _sinCamara!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (_permisoDenegado) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _iniciarCamara,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Volver a intentar'),
                                style: TextButton.styleFrom(foregroundColor: AppColors.primaryAccent),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                    child: Text(
                      hayVista
                          ? 'Encuadra la placa dentro del marco.\nLa lectura se confirma sola al estabilizarse.'
                          : 'Puedes digitar la placa para continuar con la verificación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
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
          border: Border(
            top: isTop ? side : BorderSide.none,
            bottom: !isTop ? side : BorderSide.none,
            left: isLeft ? side : BorderSide.none,
            right: !isLeft ? side : BorderSide.none,
          ),
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

/// Vista previa de la cámara a pantalla completa, recortando lo que sobre
/// (como una app de cámara) en vez de dejar bandas negras.
class _VistaPrevia extends StatelessWidget {
  final CameraController controller;
  const _VistaPrevia({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tamano = controller.value.previewSize;
    if (tamano == null) return CameraPreview(controller);
    // previewSize viene en horizontal (ancho > alto); en vertical se invierte.
    final esVertical = MediaQuery.orientationOf(context) == Orientation.portrait;
    final ancho = esVertical ? tamano.height : tamano.width;
    final alto = esVertical ? tamano.width : tamano.height;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: ancho, height: alto, child: CameraPreview(controller)),
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
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
              : const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

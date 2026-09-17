import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/parking_cell.dart';
import '../../../../core/models/parqueadero.dart';
import '../../../../core/models/vehicle.dart';
import '../../../../core/network/api_exception.dart';

/// Formulario para que el conductor solicite la reserva de una celda
/// (`POST /reservas`). La solicitud queda PENDIENTE hasta que un admin o
/// vigilante la apruebe.
///
/// Vehículos, parqueaderos y celdas disponibles salen de Api-ParkU; las
/// reglas de horario se repiten aquí para avisar antes de enviar, pero la
/// que manda es la de la API (src/config/reglasReserva.js), cuyos mensajes se
/// muestran tal cual si algo no cuadra.
///
/// Devuelve `true` por `Navigator.pop` cuando la solicitud se creó.
class DriverReserveFormPage extends StatefulWidget {
  const DriverReserveFormPage({super.key});

  @override
  State<DriverReserveFormPage> createState() => _DriverReserveFormPageState();
}

class _DriverReserveFormPageState extends State<DriverReserveFormPage> {
  // Reglas de Api-ParkU (config/horarioOperacion.js y config/reglasReserva.js).
  static const _apertura = TimeOfDay(hour: 5, minute: 0);
  static const _cierre = TimeOfDay(hour: 21, minute: 0);
  static const _ultimaHoraInicio = TimeOfDay(hour: 19, minute: 30);
  static const _anticipacionMinima = Duration(minutes: 120);
  static const _duracionMinima = Duration(minutes: 60);
  static const _motivoMinimo = 10;

  final _repo = ParkingRepository.instance;

  Vehicle? _vehiculo;
  Parqueadero? _parqueadero;
  ParkingCell? _celda;
  List<ParkingCell> _celdas = const [];
  bool _cargandoCeldas = false;
  String? _errorCeldas;

  late DateTime _fecha;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;
  final _motivoCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final vehiculos = _repo.misVehiculos();
    if (vehiculos.length == 1) _vehiculo = vehiculos.first;
    if (_repo.parqueaderos.length == 1) _parqueadero = _repo.parqueaderos.first;
    _proponerFranja();
    _cargarCeldas();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  /// Primera franja válida desde ahora: al menos 2 h de anticipación, en
  /// punto, dentro del horario y nunca un domingo. Si hoy ya no cabe, pasa
  /// al siguiente día hábil a la hora de apertura.
  void _proponerFranja() {
    var inicio = DateTime.now().add(_anticipacionMinima);
    inicio = DateTime(inicio.year, inicio.month, inicio.day, inicio.hour + (inicio.minute > 0 ? 1 : 0));
    final aperturaHoy = DateTime(inicio.year, inicio.month, inicio.day, _apertura.hour, _apertura.minute);
    final ultimaHoy = DateTime(inicio.year, inicio.month, inicio.day, _ultimaHoraInicio.hour, _ultimaHoraInicio.minute);
    if (inicio.isBefore(aperturaHoy)) inicio = aperturaHoy;
    if (inicio.isAfter(ultimaHoy)) {
      final manana = inicio.add(const Duration(days: 1));
      inicio = DateTime(manana.year, manana.month, manana.day, _apertura.hour, _apertura.minute);
    }
    while (inicio.weekday == DateTime.sunday) {
      inicio = inicio.add(const Duration(days: 1));
    }
    _fecha = DateTime(inicio.year, inicio.month, inicio.day);
    _horaInicio = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
    final fin = inicio.add(_duracionMinima);
    _horaFin = fin.day != inicio.day ? _cierre : TimeOfDay(hour: fin.hour, minute: fin.minute);
    if (_minutos(_horaFin) > _minutos(_cierre)) _horaFin = _cierre;
  }

  static int _minutos(TimeOfDay h) => h.hour * 60 + h.minute;

  DateTime _combinar(DateTime fecha, TimeOfDay hora) => DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);

  Future<void> _cargarCeldas() async {
    final vehiculo = _vehiculo;
    final parqueadero = _parqueadero;
    if (vehiculo == null || parqueadero == null) {
      setState(() {
        _celdas = const [];
        _celda = null;
        _errorCeldas = null;
      });
      return;
    }
    setState(() {
      _cargandoCeldas = true;
      _errorCeldas = null;
    });
    try {
      final celdas = await _repo.celdasDisponibles(parqueaderoId: parqueadero.id, tipo: vehiculo.tipo);
      if (!mounted) return;
      setState(() {
        _celdas = celdas;
        // Conserva la elección si sigue disponible; si no, la primera.
        _celda = celdas.where((c) => c.id == _celda?.id).firstOrNull ?? (celdas.length == 1 ? celdas.first : null);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _celdas = const [];
        _celda = null;
        _errorCeldas = e.message;
      });
    } finally {
      if (mounted) setState(() => _cargandoCeldas = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final nueva = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (d) => d.weekday != DateTime.sunday,
      helpText: 'Fecha de la reserva',
    );
    if (nueva != null) setState(() => _fecha = nueva);
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
      helpText: esInicio ? 'Hora de inicio' : 'Hora de fin',
    );
    if (seleccionada == null) return;
    setState(() {
      if (esInicio) {
        _horaInicio = seleccionada;
        // Mantiene la duración mínima si el fin quedó por debajo.
        if (_minutos(_horaFin) < _minutos(_horaInicio) + _duracionMinima.inMinutes) {
          final fin = _minutos(_horaInicio) + _duracionMinima.inMinutes;
          _horaFin = fin >= _minutos(_cierre) ? _cierre : TimeOfDay(hour: fin ~/ 60, minute: fin % 60);
        }
      } else {
        _horaFin = seleccionada;
      }
    });
  }

  String _formatoFecha(DateTime f) {
    final d = f.day.toString().padLeft(2, '0');
    final m = f.month.toString().padLeft(2, '0');
    return '$d/$m/${f.year}';
  }

  String _formatoHora(TimeOfDay h) {
    final hh = h.hour.toString().padLeft(2, '0');
    final mm = h.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Mismas reglas que valida la API, para avisar sin ir hasta el servidor.
  String? _validar() {
    if (_vehiculo == null) return 'Selecciona el vehículo';
    if (_parqueadero == null) return 'Selecciona el parqueadero';
    if (_celda == null) return 'Selecciona una celda disponible';
    if (_motivoCtrl.text.trim().length < _motivoMinimo) {
      return 'Explica para qué necesitas la celda (mínimo $_motivoMinimo caracteres)';
    }
    if (_fecha.weekday == DateTime.sunday) return 'El parqueadero no opera los domingos: elige otro día';
    final inicio = _combinar(_fecha, _horaInicio);
    final fin = _combinar(_fecha, _horaFin);
    if (!fin.isAfter(inicio)) return 'La hora de fin debe ser posterior a la de inicio';
    if (fin.difference(inicio) < _duracionMinima) return 'La reserva debe durar al menos 1 hora';
    if (_minutos(_horaInicio) < _minutos(_apertura) || _minutos(_horaFin) > _minutos(_cierre)) {
      return 'La reserva debe estar entre las ${_formatoHora(_apertura)} y las ${_formatoHora(_cierre)} (horario de operación)';
    }
    if (_minutos(_horaInicio) > _minutos(_ultimaHoraInicio)) {
      return 'Una reserva no puede empezar después de las ${_formatoHora(_ultimaHoraInicio)}';
    }
    if (inicio.difference(DateTime.now()) < _anticipacionMinima) {
      return 'La reserva debe pedirse con al menos 2 horas de anticipación';
    }
    return null;
  }

  Future<void> _enviarSolicitud() async {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      await _repo.crearReserva(
        vehiculo: _vehiculo!,
        celda: _celda!,
        inicio: _combinar(_fecha, _horaInicio),
        fin: _combinar(_fecha, _horaFin),
        motivo: _motivoCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 6)));
      // Si la celda dejó de estar disponible, se refresca la lista.
      if (e.statusCode == 409 || e.statusCode == 404) _cargarCeldas();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = _repo.misVehiculos();
    final parqueaderos = _repo.parqueaderos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: vehiculos.isEmpty
            ? EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'Primero registra un vehículo',
                subtitle: 'Una reserva se hace a nombre de uno de tus vehículos. Regístralo en la pestaña Vehículos.',
                action: OutlinedButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Volver')),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  // ─── Encabezado ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconBadge(icon: Icons.event_available_rounded, size: 52, iconSize: 26),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NUEVA SOLICITUD', style: AppTextStyles.overline.copyWith(color: AppColors.primary, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('Solicitar reserva de celda', style: AppTextStyles.heading3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ─── Texto informativo ───
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.caption.copyWith(height: 1.4),
                      children: [
                        const TextSpan(text: 'Tu solicitud queda '),
                        TextSpan(
                          text: 'pendiente',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const TextSpan(
                          text:
                              ' hasta que un administrador o vigilante la acepte — la celda no se reserva de inmediato. '
                              'Pídela con al menos 2 horas de anticipación, entre 05:00 y 21:00, de lunes a sábado.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── Vehículo ───
                  const _Label('Vehículo *'),
                  const SizedBox(height: 8),
                  _DropdownField<Vehicle>(
                    hint: 'Selecciona tu vehículo...',
                    value: _vehiculo,
                    items: [
                      for (final v in vehiculos)
                        DropdownMenuItem(
                          value: v,
                          child: Text(
                            '${ParkingRepository.formatea(v.placa)} · ${v.tipo.label}${v.marcaLinea.isEmpty ? '' : ' · ${v.marcaLinea}'}',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _vehiculo = v);
                      _cargarCeldas();
                    },
                  ),
                  const SizedBox(height: 18),

                  // ─── Parqueadero ───
                  const _Label('Parqueadero *'),
                  const SizedBox(height: 8),
                  _DropdownField<Parqueadero>(
                    hint: parqueaderos.isEmpty ? 'No hay parqueaderos activos' : 'Selecciona un parqueadero...',
                    value: _parqueadero,
                    items: [for (final p in parqueaderos) DropdownMenuItem(value: p, child: Text(p.nombreConTipo))],
                    onChanged: parqueaderos.isEmpty
                        ? null
                        : (p) {
                            setState(() {
                              _parqueadero = p;
                              _celda = null;
                            });
                            _cargarCeldas();
                          },
                  ),
                  const SizedBox(height: 18),

                  // ─── Celda ───
                  const _Label('Celda disponible *'),
                  const SizedBox(height: 8),
                  _DropdownField<ParkingCell>(
                    hint: _vehiculo == null
                        ? 'Elige primero un vehículo'
                        : _parqueadero == null
                        ? 'Elige primero un parqueadero'
                        : _cargandoCeldas
                        ? 'Buscando celdas disponibles…'
                        : _celdas.isEmpty
                        ? 'Sin celdas de ${_vehiculo!.tipo.label.toLowerCase()} disponibles'
                        : 'Selecciona una celda...',
                    value: _celda,
                    items: [
                      for (final c in _celdas)
                        DropdownMenuItem(value: c, child: Text(c.usabilidad.esPreferencial ? '${c.codigo} · ${c.usabilidad.label}' : c.codigo)),
                    ],
                    onChanged: _celdas.isEmpty ? null : (c) => setState(() => _celda = c),
                    trailing: _cargandoCeldas
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                  ),
                  if (_errorCeldas != null) ...[
                    const SizedBox(height: 6),
                    Text(_errorCeldas!, style: AppTextStyles.small.copyWith(color: AppColors.danger)),
                  ] else if (_vehiculo != null && _parqueadero != null && !_cargandoCeldas) ...[
                    const SizedBox(height: 6),
                    Text(
                      _celdas.isEmpty
                          ? 'Prueba con otro parqueadero.'
                          : '${_celdas.length} celda${_celdas.length == 1 ? '' : 's'} de ${_vehiculo!.tipo.label.toLowerCase()} disponible${_celdas.length == 1 ? '' : 's'} ahora',
                      style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ─── Fecha ───
                  const _Label('Fecha *'),
                  const SizedBox(height: 8),
                  _PickerField(value: _formatoFecha(_fecha), icon: Icons.calendar_today_rounded, onTap: _seleccionarFecha),
                  const SizedBox(height: 18),

                  // ─── Horas ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Hora de inicio *'),
                            const SizedBox(height: 8),
                            _PickerField(
                              value: _formatoHora(_horaInicio),
                              icon: Icons.access_time_rounded,
                              onTap: () => _seleccionarHora(true),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Entre ${_formatoHora(_apertura)} y ${_formatoHora(_ultimaHoraInicio)}',
                              style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('Hora de fin *'),
                            const SizedBox(height: 8),
                            _PickerField(
                              value: _formatoHora(_horaFin),
                              icon: Icons.access_time_rounded,
                              onTap: () => _seleccionarHora(false),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hasta ${_formatoHora(_cierre)} (mínimo 1 hora)',
                              style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ─── Motivo ───
                  const _Label('Motivo / Justificación *'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _motivoCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Ej. Necesito parquear mientras asisto a clase...',
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      // Botones en una barra fija al pie: antes iban al final de la lista y,
      // con el teclado abierto al escribir el motivo, quedaban tapados y
      // parecía que no había cómo enviar. Al ser bottomNavigationBar, el
      // Scaffold la sube por encima del teclado.
      bottomNavigationBar: vehiculos.isEmpty
          ? null
          : BottomActionBar(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancelar', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _enviarSolicitud,
                      icon: _enviando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_enviando ? 'Enviando…' : 'Enviar solicitud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets internos reutilizables
// ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5));
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? trailing;

  const _DropdownField({required this.hint, required this.value, required this.items, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.body.copyWith(color: AppColors.textPlaceholder, fontSize: 13.5)),
          icon: trailing ?? const Icon(Icons.keyboard_arrow_down_rounded),
          style: AppTextStyles.body.copyWith(fontSize: 13.5, color: AppColors.textPrimary),
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value, style: AppTextStyles.body.copyWith(fontSize: 13.5))),
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

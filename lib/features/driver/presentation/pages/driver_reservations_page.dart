import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';

/// Formulario para que el conductor solicite la reserva de una celda.
/// La solicitud queda PENDIENTE hasta que un admin o vigilante la apruebe.
class DriverReservePage extends StatefulWidget {
  const DriverReservePage({super.key});

  @override
  State<DriverReservePage> createState() => _DriverReservePageState();
}

class _DriverReservePageState extends State<DriverReservePage> {
  String? _vehiculo;
  String? _parqueadero;
  String? _celda;
  DateTime _fecha = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 23, minute: 59);
  TimeOfDay _horaFin = const TimeOfDay(hour: 23, minute: 59);
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final nueva = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (nueva != null) setState(() => _fecha = nueva);
  }

  Future<void> _seleccionarHora(bool esInicio) async {
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : _horaFin,
    );
    if (seleccionada != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = seleccionada;
        } else {
          _horaFin = seleccionada;
        }
      });
    }
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

  void _enviarSolicitud() {
    if (_vehiculo == null || _parqueadero == null || _celda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos obligatorios')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada — queda pendiente de aprobación'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            // ─── Encabezado ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(
                  icon: Icons.event_available_rounded,
                  size: 52,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NUEVA SOLICITUD',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Solicitar reserva de celda',
                        style: AppTextStyles.heading3,
                      ),
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
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(
                    text:
                    ' hasta que un administrador o vigilante la acepte — la celda no se reserva de inmediato.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ─── Vehículo ───
            const _Label('Vehículo *'),
            const SizedBox(height: 8),
            _DropdownField<String>(
              hint: 'Selecciona tu vehículo...',
              value: _vehiculo,
              items: const [
                DropdownMenuItem(value: 'ABC123', child: Text('ABC123')),
                DropdownMenuItem(value: 'XYZ789', child: Text('XYZ789')),
              ],
              onChanged: (v) => setState(() => _vehiculo = v),
            ),
            const SizedBox(height: 18),

            // ─── Parqueadero + Celda ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Parqueadero *'),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        hint: 'Selecciona un parqueadero...',
                        value: _parqueadero,
                        items: const [
                          DropdownMenuItem(
                              value: 'docentes', child: Text('Docentes')),
                          DropdownMenuItem(
                              value: 'estudiantes',
                              child: Text('Estudiantes')),
                        ],
                        onChanged: (v) => setState(() {
                          _parqueadero = v;
                          _celda = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Celda disponible *'),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        hint: _parqueadero == null
                            ? 'Elige primero un parqueadero'
                            : 'Selecciona una celda...',
                        value: _celda,
                        items: _parqueadero == null
                            ? const []
                            : const [
                          DropdownMenuItem(
                              value: 'A-01', child: Text('A-01')),
                          DropdownMenuItem(
                              value: 'A-02', child: Text('A-02')),
                        ],
                        onChanged: _parqueadero == null
                            ? null
                            : (v) => setState(() => _celda = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Fecha ───
            const _Label('Fecha *'),
            const SizedBox(height: 8),
            _PickerField(
              value: _formatoFecha(_fecha),
              icon: Icons.calendar_today_rounded,
              onTap: _seleccionarFecha,
            ),
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
                        'Entre 23:59 y 23:59',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
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
                        'Desde 23:59 (mínimo 1 hora)',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
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
              decoration: InputDecoration(
                hintText: 'Ej. Necesito parquear mientras asisto a clase...',
                hintStyle: AppTextStyles.caption.copyWith(
                  color: AppColors.textPlaceholder,
                ),
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
                  borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ─── Botones ───
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _enviarSolicitud,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Enviar solicitud'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
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
    return Text(
      text,
      style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

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
          hint: Text(
            hint,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPlaceholder,
              fontSize: 13.5,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
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

  const _PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
  });

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
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.body.copyWith(fontSize: 13.5),
              ),
            ),
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
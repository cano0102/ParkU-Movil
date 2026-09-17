import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/network/api_exception.dart';
import 'driver_reserve_form_page.dart';

/// Reservas de celda del conductor (`GET /reservas/vehiculo/:id` por cada
/// vehículo suyo, ya juntadas en [ParkingRepository.reservas]). Desde aquí se
/// solicita una nueva y se cancelan las que siguen vivas.
class DriverReservationsPage extends StatefulWidget {
  const DriverReservationsPage({super.key});

  @override
  State<DriverReservationsPage> createState() => _DriverReservationsPageState();
}

class _DriverReservationsPageState extends State<DriverReservationsPage> {
  final _repo = ParkingRepository.instance;
  int? _cancelando;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refrescar() async {
    try {
      await _repo.recargarMisReservas();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _nuevaSolicitud() async {
    final creada = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const DriverReserveFormPage(), fullscreenDialog: true));
    if (creada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud enviada — queda pendiente de aprobación')));
    }
  }

  Future<void> _cancelar(Reserva reserva) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text('¿Cancelar la reserva de la celda ${reserva.celdaNumero} para ${ParkingRepository.formatea(reserva.placa)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _cancelando = reserva.id);
    try {
      await _repo.cancelarReserva(reserva);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cancelando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservas = _repo.reservas;
    final activas = reservas.where((r) => r.estado.esActiva).length;
    final puedeVolver = Navigator.of(context).canPop();

    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageTopBar(
                title: 'Mis reservas',
                subtitle: reservas.isEmpty
                    ? (_repo.cargando ? 'Cargando…' : 'Sin reservas')
                    : '$activas activa${activas == 1 ? '' : 's'} · ${reservas.length} en total',
                showBack: puedeVolver,
                trailing: TopBarActionButton(icon: Icons.add_rounded, filled: true, onTap: _nuevaSolicitud),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refrescar,
                  child: reservas.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.6,
                              child: EmptyState(
                                icon: Icons.event_available_outlined,
                                title: 'Aún no tienes reservas',
                                subtitle: _repo.misVehiculos().isEmpty
                                    ? 'Registra un vehículo para poder solicitar una celda.'
                                    : 'Solicita una celda para un día y hora; portería la aprueba.',
                                action: ElevatedButton(
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                                  onPressed: _nuevaSolicitud,
                                  child: const Text('Solicitar reserva'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: reservas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final r = reservas[index];
                            return _ReservaCard(
                              reserva: r,
                              parqueadero: _repo.parqueaderoPorId(r.parqueaderoId)?.nombre,
                              cancelando: _cancelando == r.id,
                              onCancelar: r.estado.esActiva ? () => _cancelar(r) : null,
                            );
                          },
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

class _ReservaCard extends StatelessWidget {
  final Reserva reserva;
  final String? parqueadero;
  final bool cancelando;
  final VoidCallback? onCancelar;

  const _ReservaCard({required this.reserva, required this.parqueadero, required this.cancelando, required this.onCancelar});

  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _fecha(DateTime d) => '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]} ${d.year}';
  String _hora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  ChipTone get _tono {
    switch (reserva.estado) {
      case EstadoReserva.pendiente:
        return ChipTone.warning;
      case EstadoReserva.aceptada:
        return ChipTone.success;
      case EstadoReserva.rechazada:
        return ChipTone.danger;
      case EstadoReserva.terminada:
        return ChipTone.info;
      case EstadoReserva.cancelada:
        return ChipTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final celda = parqueadero == null ? reserva.celdaNumero : '${reserva.celdaNumero} · $parqueadero';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.event_available_rounded, size: 46, iconSize: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fecha(reserva.inicio).toUpperCase(), style: AppTextStyles.overline.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PlateBox(placa: ParkingRepository.formatea(reserva.placa), size: 17),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: reserva.estado.label, tone: _tono),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DataField(label: 'Celda', value: celda, icon: Icons.local_parking_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DataField(label: 'Horario', value: '${_hora(reserva.inicio)} – ${_hora(reserva.fin)}', icon: Icons.schedule_rounded),
              ),
            ],
          ),
          if (reserva.motivo != null && reserva.motivo!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            DataField(label: 'Motivo', value: reserva.motivo!.trim()),
          ],
          if (reserva.estado == EstadoReserva.rechazada && (reserva.motivoRechazo ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            DataField(label: 'Motivo del rechazo', value: reserva.motivoRechazo!.trim(), valueColor: AppColors.danger),
          ],
          if (onCancelar != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: cancelando ? null : onCancelar,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                icon: cancelando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                    : const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancelar reserva'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

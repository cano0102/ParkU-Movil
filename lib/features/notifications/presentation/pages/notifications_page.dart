import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/notificacion.dart';
import '../../../../core/network/api_exception.dart';

/// Campana de la cabecera: el icono de notificaciones con el número de no
/// leídas encima. Sirve tanto en el inicio del conductor como en el de
/// portería (mismo endpoint, distinto contenido).
class NotificationBell extends StatelessWidget {
  final int noLeidas;
  final VoidCallback onTap;

  const NotificationBell({super.key, required this.noLeidas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassIconButton(icon: noLeidas > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, onTap: onTap),
        if (noLeidas > 0)
          Positioned(
            top: -4,
            right: -4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  noLeidas > 99 ? '99+' : '$noLeidas',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Lista de notificaciones del usuario (`GET /notificaciones`): para el
/// conductor, los avisos de ingreso/salida de su vehículo y del estado de
/// sus reservas (los mismos que recibe por correo).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = ParkingRepository.instance;
  bool _marcando = false;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChanged);
    // Se refresca al abrir: lo que llegó desde la última carga de la app.
    _repo.recargarNotificaciones();
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
      await _repo.recargarNotificaciones();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _marcarTodas() async {
    setState(() => _marcando = true);
    try {
      await _repo.marcarTodasNotificacionesLeidas();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _marcando = false);
    }
  }

  Future<void> _tocar(Notificacion n) async {
    try {
      await _repo.marcarNotificacionLeida(n);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificaciones = _repo.notificaciones;
    final noLeidas = _repo.notificacionesNoLeidas;

    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageTopBar(
                title: 'Notificaciones',
                subtitle: notificaciones.isEmpty
                    ? 'Sin notificaciones'
                    : noLeidas == 0
                        ? 'Todo leído'
                        : '$noLeidas sin leer',
                showBack: true,
                trailing: noLeidas > 0
                    ? TopBarActionButton(icon: _marcando ? Icons.hourglass_top_rounded : Icons.done_all_rounded, onTap: _marcando ? null : _marcarTodas)
                    : null,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refrescar,
                  child: notificaciones.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: constraints.maxHeight,
                                child: const EmptyState(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Aún no tienes notificaciones',
                                  subtitle: 'Aquí verás cuándo ingresa o sale tu vehículo y qué pasa con tus reservas. Desliza hacia abajo para actualizar.',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: notificaciones.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final n = notificaciones[index];
                            return _NotificacionTile(notificacion: n, onTap: () => _tocar(n));
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

class _NotificacionTile extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback onTap;

  const _NotificacionTile({required this.notificacion, required this.onTap});

  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _cuando(DateTime d) {
    final ahora = DateTime.now();
    final hhmm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final mismoDia = d.year == ahora.year && d.month == ahora.month && d.day == ahora.day;
    if (mismoDia) return hhmm;
    final ayer = ahora.subtract(const Duration(days: 1));
    if (d.year == ayer.year && d.month == ayer.month && d.day == ayer.day) return 'ayer $hhmm';
    return '${d.day} ${_meses[d.month - 1]} $hhmm';
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    final Color fondo;
    switch (notificacion.tipo) {
      case TipoNotificacion.acceso:
        icon = Icons.directions_car_rounded;
        color = AppColors.primaryDark;
        fondo = AppColors.primarySoft;
      case TipoNotificacion.reserva:
        icon = Icons.event_available_rounded;
        color = AppColors.warningDark;
        fondo = AppColors.warningSoft;
      case TipoNotificacion.novedad:
        icon = Icons.report_gmailerrorred_rounded;
        color = AppColors.dangerDarker;
        fondo = AppColors.dangerSoft;
      case TipoNotificacion.cambioEstado:
      case TipoNotificacion.alerta:
        icon = Icons.info_outline_rounded;
        color = AppColors.info;
        fondo = AppColors.infoSoft;
    }
    final leida = notificacion.leida;

    return AppCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      borderColor: leida ? null : AppColors.primarySoftBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, size: 40, iconSize: 20, color: color, background: fondo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notificacion.titulo,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 14, color: leida ? AppColors.textSecondary : AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_cuando(notificacion.fecha), style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder)),
                    if (!leida) ...[
                      const SizedBox(width: 6),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notificacion.mensaje,
                  style: AppTextStyles.small.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

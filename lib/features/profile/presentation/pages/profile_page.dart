import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/data/session_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ParkingRepository _repo = ParkingRepository.instance;

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

  String get _iniciales {
    final nombre = _repo.guardaNombre.trim();
    if (nombre.isEmpty) return 'U';
    final partes = nombre.split(RegExp(r'\s+'));
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return partes.first.substring(0, 1).toUpperCase();
  }

  void _sincronizar() {
    _repo.sincronizar();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Registros sincronizados correctamente'), duration: Duration(seconds: 2)));
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión de guarda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await SessionRepository.instance.cerrarSesion();
      _repo.reiniciarCache();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrosHoy = _repo.historialFiltrado('Hoy').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ProfileHeader(
            iniciales: _iniciales,
            nombre: _repo.guardaNombre,
            rol: _repo.guardaRol,
            correo: _repo.guardaCorreo,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: DataField(label: 'Portería asignada', value: _repo.porteria, icon: Icons.door_front_door_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: DataField(label: 'Turno', value: _repo.turno, icon: Icons.schedule_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: DataField(label: 'Sede', value: _repo.sede, icon: Icons.location_on_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: DataField(label: 'Registros hoy', value: '$registrosHoy', icon: Icons.receipt_long_outlined)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'PREFERENCIAS'),
                const SizedBox(height: 10),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Alertas de vehículos no autorizados',
                        value: _repo.alertasNoAutorizados,
                        onChanged: _repo.actualizarAlertas,
                      ),
                      const Divider(indent: 66),
                      SettingsTile(
                        icon: Icons.cloud_off_outlined,
                        title: 'Modo sin conexión',
                        subtitle: 'Guarda registros y sincroniza al volver la red',
                        value: _repo.modoSinConexion,
                        onChanged: _repo.actualizarModoSinConexion,
                      ),
                      const Divider(indent: 66),
                      SettingsTile(
                        icon: Icons.sync_rounded,
                        iconColor: AppColors.primaryDark,
                        iconBackground: AppColors.primarySoft,
                        title: 'Sincronizar ahora',
                        subtitle: _repo.registrosPendientesSync > 0 ? '${_repo.registrosPendientesSync} registros pendientes' : 'Todo sincronizado',
                        onTap: _sincronizar,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                LogoutButton(onPressed: _cerrarSesion),
                const SizedBox(height: 14),
                Center(child: Text('ParkU · SENA', style: AppTextStyles.small)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

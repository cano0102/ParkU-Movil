import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/data/parking_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repo = ParkingRepository.instance;

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
    final partes = _repo.guardaNombre.trim().split(RegExp(r'\s+'));
    if (partes.length >= 2) return (partes[0][0] + partes[1][0]).toUpperCase();
    return partes.first.substring(0, 1).toUpperCase();
  }

  void _sincronizar() {
    _repo.sincronizar();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registros sincronizados correctamente')));
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
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(_iniciales, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_repo.guardaNombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(_repo.guardaRol, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.82))),
                        Text(_repo.guardaCorreo, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.68))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Expanded(child: _dato('Portería asignada', _repo.porteria)), Expanded(child: _dato('Turno', _repo.turno))]),
                        const SizedBox(height: 16),
                        Row(children: [Expanded(child: _dato('Sede', _repo.sede)), Expanded(child: _dato('Registros hoy', '${_repo.historialFiltrado('Hoy').length}'))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        _switchTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Alertas de vehículos no autorizados',
                          value: _repo.alertasNoAutorizados,
                          onChanged: _repo.actualizarAlertas,
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _switchTile(
                          icon: Icons.cloud_off_outlined,
                          label: 'Modo sin conexión',
                          subtitle: 'Guarda registros y sincroniza al volver la red',
                          value: _repo.modoSinConexion,
                          onChanged: _repo.actualizarModoSinConexion,
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        InkWell(
                          onTap: _sincronizar,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.sync, size: 22, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Sincronizar ahora', style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                                      Text(
                                        _repo.registrosPendientesSync > 0 ? '${_repo.registrosPendientesSync} registros pendientes' : 'Todo sincronizado',
                                        style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textPlaceholder),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.dangerSoftBorder, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _cerrarSesion,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 20, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Text('Cerrar sesión', style: AppTextStyles.bodyBold.copyWith(color: AppColors.danger, fontSize: 14)),
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
    );
  }

  Widget _dato(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.small),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                if (subtitle != null) Text(subtitle, style: AppTextStyles.small.copyWith(color: AppColors.textPlaceholder)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

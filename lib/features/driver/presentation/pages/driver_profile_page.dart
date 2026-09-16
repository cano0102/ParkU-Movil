import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/data/session_repository.dart';
import 'driver_vehicles_page.dart';

/// Perfil del conductor: sus datos, notificaciones de su vehículo y
/// cierre de sesión.
class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
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
    final nombre = _repo.conductorNombre.trim();
    if (nombre.isEmpty) return 'U';
    final partes = nombre.split(RegExp(r'\s+'));
    if (partes.length >= 2) return (partes[0][0] + partes[1][0]).toUpperCase();
    return partes.first.substring(0, 1).toUpperCase();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar tu sesión?'),
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
    final vehiculos = _repo.misVehiculos();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ProfileHeader(
            iniciales: _iniciales,
            nombre: _repo.conductorNombre,
            rol: _repo.conductorRolTexto,
            correo: _repo.conductorCorreo,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: DataField(label: 'Documento', value: _repo.conductorDocumento, icon: Icons.badge_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: DataField(label: 'Vehículos', value: '${vehiculos.length}', icon: Icons.directions_car_outlined)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DataField(label: 'Sede', value: _repo.sede, icon: Icons.location_on_outlined),
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
                        icon: Icons.notifications_active_outlined,
                        title: 'Notificar ingresos y salidas de mi vehículo',
                        value: _repo.alertasVehiculoConductor,
                        onChanged: _repo.actualizarAlertasVehiculoConductor,
                      ),
                      const Divider(indent: 66),
                      SettingsTile(
                        icon: Icons.directions_car_outlined,
                        iconColor: AppColors.primaryDark,
                        iconBackground: AppColors.primarySoft,
                        title: 'Mis vehículos',
                        subtitle: vehiculos.isEmpty ? 'Aún no has registrado ninguno' : '${vehiculos.length} registrado${vehiculos.length == 1 ? '' : 's'}',
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverVehiclesPage())),
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

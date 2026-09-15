import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
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
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // INICIALES
  // ============================================================

  String get _iniciales {
    final nombre = _repo.guardaNombre.trim();

    if (nombre.isEmpty) {
      return 'U';
    }

    final partes = nombre.split(RegExp(r'\s+'));

    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }

    return partes.first.substring(0, 1).toUpperCase();
  }

  // ============================================================
  // SINCRONIZAR
  // ============================================================

  void _sincronizar() {
    _repo.sincronizar();

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Registros sincronizados correctamente',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            '¿Seguro que deseas cerrar tu sesión de guarda?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              onPressed: () {
                Navigator.pop(ctx, true);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmar == true && mounted) {
      await SessionRepository.instance.cerrarSesion();
      _repo.reiniciarCache();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
            (route) => false,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final registrosHoy = _repo.historialFiltrado('Hoy').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            _buildHeader(),

            // ====================================================
            // CONTENIDO
            // ====================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Información
                        _buildInfoCard(
                          registrosHoy: registrosHoy,
                        ),

                        const SizedBox(height: 10),

                        // Configuración
                        _buildSettingsCard(),

                        const SizedBox(height: 10),

                        // Cerrar sesión
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _iniciales,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _repo.guardaNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _repo.guardaRol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  _repo.guardaCorreo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(
                      alpha: 0.68,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA INFORMACIÓN
  // ============================================================

  Widget _buildInfoCard({
    required int registrosHoy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dato(
                  'Portería asignada',
                  _repo.porteria,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dato(
                  'Turno',
                  _repo.turno,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _dato(
                  'Sede',
                  _repo.sede,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dato(
                  'Registros hoy',
                  '$registrosHoy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TARJETA CONFIGURACIÓN
  // ============================================================

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ALERTAS
          _switchTile(
            icon: Icons.notifications_none_rounded,
            label: 'Alertas de vehículos no autorizados',
            value: _repo.alertasNoAutorizados,
            onChanged: _repo.actualizarAlertas,
          ),

          const Divider(
            height: 1,
            color: AppColors.divider,
          ),

          // MODO SIN CONEXIÓN
          _switchTile(
            icon: Icons.cloud_off_outlined,
            label: 'Modo sin conexión',
            subtitle:
            'Guarda registros y sincroniza al volver la red',
            value: _repo.modoSinConexion,
            onChanged: _repo.actualizarModoSinConexion,
          ),

          const Divider(
            height: 1,
            color: AppColors.divider,
          ),

          // SINCRONIZAR
          InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: _sincronizar,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Icono
                  _iconContainer(
                    Icons.sync_rounded,
                  ),

                  const SizedBox(width: 10),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sincronizar ahora',
                          style:
                          AppTextStyles.bodyBold.copyWith(
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 1),

                        Text(
                          _repo.registrosPendientesSync > 0
                              ? '${_repo.registrosPendientesSync} registros pendientes'
                              : 'Todo sincronizado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                          AppTextStyles.small.copyWith(
                            fontSize: 10.5,
                            color:
                            AppColors.textPlaceholder,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textPlaceholder,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SWITCH TILE
  // ============================================================

  Widget _switchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      child: Row(
        children: [
          // Icono
          _iconContainer(icon),

          const SizedBox(width: 10),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 13,
                  ),
                ),

                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      fontSize: 10,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 5),

          // Switch
          Transform.scale(
            scale: 0.90,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENEDOR DE ICONOS
  // ============================================================

  Widget _iconContainer(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        size: 18,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ============================================================
  // DATO
  // ============================================================

  Widget _dato(
      String label,
      String value,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.small.copyWith(
            fontSize: 10,
            color: AppColors.textPlaceholder,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CERRAR SESIÓN
  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: AppColors.dangerSoftBorder,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        onPressed: _cerrarSesion,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              size: 18,
              color: AppColors.danger,
            ),

            const SizedBox(width: 7),

            Text(
              'Cerrar sesión',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.danger,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart';

/// Historial de movimientos de los vehículos del conductor actual.
class DriverHistoryPage extends StatefulWidget {
  const DriverHistoryPage({super.key});

  @override
  State<DriverHistoryPage> createState() => _DriverHistoryPageState();
}

class _DriverHistoryPageState extends State<DriverHistoryPage> {
  final _repo = ParkingRepository.instance;
  String _filtro = 'Hoy';

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

  @override
  Widget build(BuildContext context) {
    final registros = _repo.historialDeConductorFiltrado(_filtro);
    final ingresos = registros.where((r) => r.estado == AccessStatus.dentro).length;
    final salidas = registros.where((r) => r.estado == AccessStatus.salio).length;

    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageTopBar(title: 'Mi historial', subtitle: 'Ingresos y salidas de tus vehículos'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilterChipsRow(options: const ['Hoy', 'Ayer', '7 días'], selected: _filtro, onSelected: (f) => setState(() => _filtro = f)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(label: 'Ingresos', value: '$ingresos', icon: Icons.login_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(label: 'Salidas', value: '$salidas', icon: Icons.logout_rounded, accent: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: registros.isEmpty
                    ? const EmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        title: 'Sin movimientos en este periodo',
                        subtitle: 'Cuando ingreses o salgas del campus, tus movimientos aparecerán aquí.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: registros.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => MovementTile(record: registros[index], showStatus: true),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

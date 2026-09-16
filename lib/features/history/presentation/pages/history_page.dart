import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/models/access_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
    final registros = _repo.historialFiltrado(_filtro);
    final ingresos = registros.where((r) => r.estado == AccessStatus.dentro).length;
    final salidas = registros.where((r) => r.estado == AccessStatus.salio).length;
    final novedades = registros.where((r) => r.estado == AccessStatus.novedad).length;

    return DarkStatusBarIcons(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageTopBar(
                title: 'Historial',
                subtitle: 'Movimientos de portería',
                trailing: TopBarActionButton(
                  icon: Icons.tune_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usa los filtros de periodo para acotar el historial'))),
                ),
              ),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(label: 'Novedades', value: '$novedades', icon: Icons.report_gmailerrorred_rounded, accent: AppColors.danger),
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
                        subtitle: 'Prueba con otro rango de fechas o registra un ingreso desde el escáner.',
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

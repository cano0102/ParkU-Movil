import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
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

  Color _pillBg(AccessStatus estado) {
    switch (estado) {
      case AccessStatus.dentro:
        return AppColors.primarySoft;
      case AccessStatus.salio:
        return AppColors.neutralSoft;
      case AccessStatus.novedad:
        return AppColors.dangerSoft;
    }
  }

  Color _pillFg(AccessStatus estado) {
    switch (estado) {
      case AccessStatus.dentro:
        return AppColors.primaryDark;
      case AccessStatus.salio:
        return AppColors.textSecondary;
      case AccessStatus.novedad:
        return AppColors.dangerDarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final registros = _repo.historialDeConductorFiltrado(_filtro);
    final ingresos = registros.where((r) => r.estado == AccessStatus.dentro).length;
    final salidas = registros.where((r) => r.estado == AccessStatus.salio).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi historial', style: AppTextStyles.heading2, overflow: TextOverflow.ellipsis, maxLines: 1),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Hoy', 'Ayer', '7 días'].map((f) {
                        final seleccionado = f == _filtro;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setState(() => _filtro = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: seleccionado ? AppColors.primary : Colors.white,
                                border: seleccionado ? null : Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: seleccionado ? Colors.white : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _statCard('Ingresos', '$ingresos')),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('Salidas', '$salidas')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: registros.isEmpty
                  ? Center(
                      child: Text(
                        'Sin movimientos en este periodo',
                        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                      itemCount: registros.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = registros[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: AppColors.neutralSoft, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.directions_car, size: 19, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.placa, style: AppTextStyles.mono(size: 15, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(r.detalle, style: AppTextStyles.small.copyWith(color: AppColors.textMuted), overflow: TextOverflow.ellipsis, maxLines: 1),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(TimeOfDay.fromDateTime(r.hora).format(context), style: AppTextStyles.mono(size: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(color: _pillBg(r.estado), borderRadius: BorderRadius.circular(999)),
                                    child: Text(r.estadoLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _pillFg(r.estado))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 22)),
        ],
      ),
    );
  }
}

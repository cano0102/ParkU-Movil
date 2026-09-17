import 'package:flutter/material.dart';
import '../../../../app/widgets/app_bottom_nav.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../scan/presentation/pages/scan_plate_page.dart';
import 'home_dashboard_page.dart';

/// Contenedor con la barra de navegación inferior (Inicio, Escanear,
/// Historial, Perfil) que se ve en el diseño en las pantallas 02, 08 y 09.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Inicio'),
    AppNavItem(icon: Icons.qr_code_scanner_rounded, activeIcon: Icons.qr_code_scanner_rounded, label: 'Escanear'),
    AppNavItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'Historial'),
    AppNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil'),
  ];

  late final _tabs = [
    HomeDashboardPage(onVerTodo: () => setState(() => _index = 1)),
    const HistoryPage(),
    const ProfilePage(),
  ];

  void _onTap(int tappedIndex) {
    if (tappedIndex == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanPlatePage()));
      return;
    }
    setState(() => _index = tappedIndex <= 1 ? 0 : tappedIndex - 1);
    // Al abrir Historial se refresca desde la API (ingresos/salidas que
    // registró otro guarda o el panel web).
    if (tappedIndex == 2) ParkingRepository.instance.recargarHistorial().catchError((_) {});
  }

  int get _navSelectedIndex {
    if (_index == 0) return 0;
    if (_index == 1) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(items: _items, selectedIndex: _navSelectedIndex, onTap: _onTap),
    );
  }
}

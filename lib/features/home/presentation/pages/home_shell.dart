import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
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
      bottomNavigationBar: _BottomNav(selectedIndex: _navSelectedIndex, onTap: _onTap),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_filled, 'Inicio'),
      (Icons.qr_code_scanner, 'Escanear'),
      (Icons.history, 'Historial'),
      (Icons.person, 'Perfil'),
    ];
    return Container(
      height: 82,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.only(bottom: 14, top: 6),
      child: Row(
        children: List.generate(items.length, (i) {
          final selected = selectedIndex == i;
          final color = selected ? AppColors.primary : AppColors.textPlaceholder;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i].$1, size: 24, color: color),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$2,
                    style: TextStyle(fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w700, color: color),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

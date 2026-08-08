import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import 'driver_history_page.dart';
import 'driver_home_page.dart';
import 'driver_profile_page.dart';
import 'driver_vehicles_page.dart';

/// Contenedor con la barra de navegación inferior del conductor
/// (Inicio, Mis vehículos, Historial, Perfil).
class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;

  late final _tabs = [
    DriverHomePage(onVerTodo: () => setState(() => _index = 2)),
    const DriverVehiclesPage(),
    const DriverHistoryPage(),
    const DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _BottomNav(selectedIndex: _index, onTap: (i) => setState(() => _index = i)),
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
      (Icons.directions_car, 'Vehículos'),
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

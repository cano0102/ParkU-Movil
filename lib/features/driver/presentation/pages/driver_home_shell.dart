import 'package:flutter/material.dart';
import '../../../../app/widgets/app_bottom_nav.dart';
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

  static const _items = [
    AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Inicio'),
    AppNavItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car_rounded, label: 'Vehículos'),
    AppNavItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'Historial'),
    AppNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Perfil'),
  ];

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
      bottomNavigationBar: AppBottomNav(items: _items, selectedIndex: _index, onTap: (i) => setState(() => _index = i)),
    );
  }
}

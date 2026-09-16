import 'package:flutter/material.dart';
import '../../../../app/widgets/app_bottom_nav.dart';
import 'driver_home_page.dart' hide DriverReservePage;
import 'driver_history_page.dart';
import 'driver_profile_page.dart';
import 'driver_reservations_page.dart';
import 'driver_vehicles_page.dart';

class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});

  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;

  //   0 → Inicio
  //   1 → Vehículos
  //   2 → Historial
  //   3 → Reservas
  //   4 → Perfil
  static const _items = [
    AppNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    AppNavItem(
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_rounded,
      label: 'Vehículos',
    ),
    AppNavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history_rounded,
      label: 'Historial',
    ),
    AppNavItem(
      icon: Icons.event_available_outlined,
      activeIcon: Icons.event_available_rounded,
      label: 'Reservas',
    ),
    AppNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  late final List<Widget> _tabs = [
    DriverHomePage(onVerTodo: () => setState(() => _index = 2)), // 0 → Inicio
    const DriverVehiclesPage(),                                   // 1 → Vehículos
    const DriverHistoryPage(),                                    // 2 → Historial
    const DriverReservePage(),                               // 3 → Reservas
    const DriverProfilePage(),                                    // 4 → Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: AppBottomNav(
        items: _items,
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
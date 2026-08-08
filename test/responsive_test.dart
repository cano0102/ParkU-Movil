// Verifica que las pantallas principales no generen overflow de layout
// en distintos tamaños de teléfono: desde uno pequeño (iPhone SE) hasta
// uno grande (gama alta actual), pasando por el ancho más común en
// Android (360dp).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parku_movil/core/data/parking_repository.dart';
import 'package:parku_movil/features/auth/presentation/pages/login.dart';
import 'package:parku_movil/features/driver/presentation/pages/driver_history_page.dart';
import 'package:parku_movil/features/driver/presentation/pages/driver_home_page.dart';
import 'package:parku_movil/features/driver/presentation/pages/driver_pass_page.dart';
import 'package:parku_movil/features/driver/presentation/pages/driver_profile_page.dart';
import 'package:parku_movil/features/driver/presentation/pages/driver_vehicles_page.dart';
import 'package:parku_movil/features/exit/presentation/pages/exit_register_page.dart';
import 'package:parku_movil/features/history/presentation/pages/history_page.dart';
import 'package:parku_movil/features/home/presentation/pages/home_dashboard_page.dart';
import 'package:parku_movil/features/home/presentation/pages/welcome_page.dart';
import 'package:parku_movil/features/parking_map/presentation/pages/cell_detail_page.dart';
import 'package:parku_movil/features/parking_map/presentation/pages/parking_map_page.dart';
import 'package:parku_movil/features/profile/presentation/pages/profile_page.dart';
import 'package:parku_movil/features/scan/presentation/pages/confirm_plate_page.dart';
import 'package:parku_movil/features/scan/presentation/pages/scan_plate_page.dart';
import 'package:parku_movil/features/scan/presentation/pages/vehicle_authorized_page.dart';
import 'package:parku_movil/features/scan/presentation/pages/vehicle_denied_page.dart';

const _tamanosDeTelefono = {
  'pequeño (iPhone SE, 320x568)': Size(320, 568),
  'común en Android (360x800)': Size(360, 800),
  'estándar (390x844)': Size(390, 844),
  'grande (430x932)': Size(430, 932),
};

void main() {
  for (final entry in _tamanosDeTelefono.entries) {
    testWidgets('pantallas sin overflow en tamano ${entry.key}', (tester) async {
      await tester.binding.setSurfaceSize(entry.value);
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = ParkingRepository.instance;
      final vehicle = repo.buscarVehiculo('WGY482')!;
      final zona = repo.zonas.first;
      final celdaOcupada = zona.celdas.firstWhere((c) => c.esOcupada);

      final pantallas = <String, Widget>{
        'Bienvenida': const WelcomePage(),
        'Login': const LoginPage(),
        'Inicio': const HomeDashboardPage(),
        'Escanear placa': const ScanPlatePage(),
        'Confirmar placa': const ConfirmPlatePage(placaDetectada: 'WGY482'),
        'Vehículo autorizado': VehicleAuthorizedPage(vehicle: vehicle),
        'Vehículo no autorizado': const VehicleDeniedPage(placa: 'TQP71D'),
        'Registrar salida': const ExitRegisterPage(),
        'Historial': const HistoryPage(),
        'Perfil': const ProfilePage(),
        'Mapa del parqueadero': const ParkingMapPage(),
        'Elegir celda (asignación)': ParkingMapPage(vehicleParaAsignar: vehicle),
        'Detalle de celda ocupada': CellDetailPage(zona: zona, celdaInicial: celdaOcupada),
        'Inicio del conductor': const DriverHomePage(),
        'Mis vehículos': const DriverVehiclesPage(),
        'Mi pase digital': const DriverPassPage(),
        'Historial del conductor': const DriverHistoryPage(),
        'Perfil del conductor': const DriverProfilePage(),
      };

      final fallos = <String>[];
      for (final pantalla in pantallas.entries) {
        await tester.pumpWidget(MaterialApp(home: pantalla.value));
        await tester.pump();
        final error = tester.takeException();
        if (error != null) {
          fallos.add('"${pantalla.key}": $error');
        }
      }
      expect(fallos, isEmpty, reason: fallos.join('\n---\n'));
    });
  }
}

// Verifica que las pantallas principales no generen overflow de layout
// en distintos tamaños de teléfono: desde uno pequeño (iPhone SE) hasta
// uno grande (gama alta actual), pasando por el ancho más común en
// Android (360dp).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parku_movil/core/models/parking_cell.dart';
import 'package:parku_movil/core/models/parking_zone.dart';
import 'package:parku_movil/core/models/vehicle.dart';
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
import 'package:parku_movil/features/splash/presentation/pages/splash_page.dart';

const _tamanosDeTelefono = {
  'pequeño (iPhone SE, 320x568)': Size(320, 568),
  'común en Android (360x800)': Size(360, 800),
  'estándar (390x844)': Size(390, 844),
  'grande (430x932)': Size(430, 932),
};

void main() {
  for (final entry in _tamanosDeTelefono.entries) {
    testWidgets('pantallas sin overflow en tamano ${entry.key}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(entry.value);
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Datos de muestra construidos localmente: el repositorio ahora
      // consulta Api-ParkU y en las pruebas no hay red.
      const vehicle = Vehicle(
        placa: 'WGY482',
        tipo: VehicleType.carro,
        marcaLinea: 'Mazda 3',
        color: 'Gris',
        soatVigente: true,
        conductorNombre: 'Laura Gómez',
        conductorRol: 'Aprendiz',
        conductorDocumento: 'CC 1.020.334.556',
      );
      final celdaOcupada = ParkingCell(
        codigo: 'A-07',
        estado: CellStatus.ocupada,
        placa: 'WGY 482',
        conductorNombre: 'Laura Gómez',
        conductorRol: 'Aprendiz',
        desde: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      );
      final zona = ParkingZone(
        etiqueta: 'Carros',
        tipo: VehicleType.carro,
        celdas: [
          for (var i = 1; i <= 6; i++) ParkingCell(codigo: 'A-0$i'),
          celdaOcupada,
          ParkingCell(codigo: 'A-08', estado: CellStatus.reserva),
          ParkingCell(codigo: 'A-09', estado: CellStatus.mantenimiento),
          ParkingCell(codigo: 'A-10'),
        ],
      );

      final pantallas = <String, Widget>{
        'Introducción': const SplashPage(),
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

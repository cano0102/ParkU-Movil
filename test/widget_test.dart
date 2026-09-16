import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:parku_movil/app/app.dart';

void main() {
  setUp(() {
    // Sin token guardado: la introducción debe terminar en la bienvenida.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('La app arranca, pasa por la introducción y muestra la bienvenida', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkUApp());

    // Introducción visible en el primer cuadro.
    expect(find.text('ParkU'), findsOneWidget);
    expect(find.text('Ingresar'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });
}

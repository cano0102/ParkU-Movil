import 'package:flutter_test/flutter_test.dart';

import 'package:parku_movil/app/app.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de bienvenida', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkUApp());
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:parku_movil/core/models/vehicle.dart';
import 'package:parku_movil/core/utils/validators.dart';

void main() {
  group('Validators.correo', () {
    test('rechaza vacío', () {
      expect(Validators.correo(''), isNotNull);
      expect(Validators.correo(null), isNotNull);
    });

    test('rechaza un correo sin formato válido', () {
      expect(Validators.correo('no-es-correo'), isNotNull);
      expect(Validators.correo('nombre@'), isNotNull);
      expect(Validators.correo('nombre@sena'), isNotNull);
      expect(Validators.correo('nombre sin arroba@sena.edu.co'), isNotNull);
    });

    test('acepta un correo institucional válido', () {
      expect(Validators.correo('aprendiz@sena.edu.co'), isNull);
      expect(Validators.correo('  aprendiz@sena.edu.co  '), isNull);
    });
  });

  group('Validators.contrasenaNueva', () {
    test('exige al menos 8 caracteres', () {
      expect(Validators.contrasenaNueva('Abc123'), isNotNull);
    });

    test('exige mayúscula, minúscula y número', () {
      expect(
        Validators.contrasenaNueva('abcdefgh'),
        isNotNull,
      ); // sin mayúscula ni número
      expect(
        Validators.contrasenaNueva('ABCDEFGH'),
        isNotNull,
      ); // sin minúscula ni número
      expect(Validators.contrasenaNueva('Abcdefgh'), isNotNull); // sin número
    });

    test(
      'acepta una contraseña que cumple la política (igual que el backend)',
      () {
        expect(Validators.contrasenaNueva('Abcdef12'), isNull);
      },
    );
  });

  group('Validators.confirmarContrasena', () {
    test('rechaza vacío aunque el original también lo esté', () {
      final original = TextEditingController(text: '');
      expect(Validators.confirmarContrasena(original)(''), isNotNull);
    });

    test(
      'rechaza si no coincide y lee siempre el valor MÁS RECIENTE del controller',
      () {
        final original = TextEditingController(text: 'Abcdef12');
        final validator = Validators.confirmarContrasena(original);
        expect(validator('Otra123'), isNotNull);

        // El usuario corrige la contraseña original DESPUÉS de crear el validador:
        // debe comparar contra el valor actual, no contra el que tenía al crearse.
        original.text = 'Otra123';
        expect(validator('Otra123'), isNull);
      },
    );
  });

  group('Validators.placa', () {
    test('exige el formato de carro (3 letras + 3 números)', () {
      expect(Validators.placa('ABC123', VehicleType.carro), isNull);
      expect(
        Validators.placa('abc123', VehicleType.carro),
        isNull,
      ); // normaliza mayúsculas
      expect(Validators.placa('AB123', VehicleType.carro), isNotNull);
      expect(
        Validators.placa('ABC12D', VehicleType.carro),
        isNotNull,
      ); // formato de moto
    });

    test(
      'exige el formato de moto (3 letras + 2 números + letra final opcional)',
      () {
        expect(Validators.placa('ABC12D', VehicleType.moto), isNull);
        expect(
          Validators.placa('ABC12', VehicleType.moto),
          isNull,
        ); // formato antiguo sin letra
        expect(
          Validators.placa('ABC123', VehicleType.moto),
          isNotNull,
        ); // formato de carro
      },
    );

    test('rechaza vacío', () {
      expect(Validators.placa('', VehicleType.carro), isNotNull);
    });
  });

  group('Validators.placaCualquierTipo', () {
    test('acepta carro o moto sin saber el tipo de antemano', () {
      expect(Validators.placaCualquierTipo('ABC123'), isNull);
      expect(Validators.placaCualquierTipo('ABC12D'), isNull);
      expect(Validators.placaCualquierTipo('ABCD12'), isNotNull);
    });
  });

  group('Validators.textoLargo', () {
    test('exige un mínimo de caracteres', () {
      expect(Validators.textoLargo('corto', min: 10), isNotNull);
    });

    test('exige un máximo de caracteres', () {
      expect(Validators.textoLargo('a' * 501, min: 10, max: 500), isNotNull);
    });

    test('acepta un texto dentro del rango', () {
      expect(
        Validators.textoLargo(
          'Descripción suficientemente larga',
          min: 10,
          max: 500,
        ),
        isNull,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:parku_movil/features/scan/domain/plate_reader.dart';

void main() {
  group('PlateReader.extraer', () {
    test('reconoce placas de carro y de moto tal cual', () {
      expect(PlateReader.extraer('WGY482'), 'WGY482');
      expect(PlateReader.extraer('TQP71D'), 'TQP71D');
    });

    test('ignora espacios, guiones y minúsculas', () {
      expect(PlateReader.extraer('wgy 482'), 'WGY482');
      expect(PlateReader.extraer('WGY-482'), 'WGY482');
      expect(PlateReader.extraer('tqp-71d'), 'TQP71D');
    });

    test('encuentra la placa entre el resto del texto que ve el OCR', () {
      expect(PlateReader.extraer('COLOMBIA\nWGY 482\nBOGOTA D.C.'), 'WGY482');
      expect(PlateReader.extraer('MAZDA WGY482 SENA'), 'WGY482');
    });

    test('corrige confusiones típicas según la posición', () {
      // 0 leído como O en la parte numérica; O leído como 0 en las letras.
      expect(PlateReader.extraer('WGY4O2'), 'WGY402');
      expect(PlateReader.extraer('0GY482'), 'OGY482');
      // B/8, I/1, S/5.
      expect(PlateReader.extraer('WGY4B2'), 'WGY482');
      expect(PlateReader.extraer('TQPI1D'), 'TQP11D');
      expect(PlateReader.extraer('ABC5S3'), 'ABC553');
    });

    test('no inventa placas donde no hay', () {
      expect(PlateReader.extraer('PARQUEADERO SENA'), isNull);
      expect(PlateReader.extraer(''), isNull);
      expect(PlateReader.extraer('12345'), isNull);
    });
  });
}

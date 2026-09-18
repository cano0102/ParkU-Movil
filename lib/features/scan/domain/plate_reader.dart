/// Extrae una placa colombiana del texto que devuelve el OCR.
///
/// Formatos válidos (los mismos que acepta Api-ParkU):
///   - Carro: 3 letras + 3 dígitos  (`WGY482`)
///   - Moto:  3 letras + 2 dígitos + 1 letra (`TQP71D`)
///
/// El OCR confunde con frecuencia caracteres parecidos (O/0, I/1, B/8, S/5,
/// Z/2, G/6). Como la posición dentro de la placa dice si debe ir una letra o
/// un dígito, aquí se corrigen esas confusiones antes de validar: "WGY4B2"
/// leído en un carro se interpreta como "WGY482".
class PlateReader {
  PlateReader._();

  static final RegExp _formato = RegExp(r'^[A-Z]{3}[0-9]{2}[0-9A-Z]$');

  /// Dígito → letra parecida (para las tres primeras posiciones).
  static const Map<String, String> _aLetra = {'0': 'O', '1': 'I', '8': 'B', '5': 'S', '2': 'Z', '6': 'G', '4': 'A', '7': 'T'};

  /// Letra → dígito parecido (para las posiciones numéricas).
  static const Map<String, String> _aDigito = {
    'O': '0',
    'Q': '0',
    'D': '0',
    'I': '1',
    'L': '1',
    'B': '8',
    'S': '5',
    'Z': '2',
    'G': '6',
    'T': '7',
    'A': '4',
  };

  /// Placa encontrada en [texto], o `null`. El OCR devuelve todo lo que ve
  /// (pegatinas, marca del carro, letreros), así que primero se busca una
  /// placa bien formada en cualquier línea y solo si no la hay se intenta
  /// corregir UNA confusión de carácter. Con más de una corrección casi
  /// cualquier palabra de seis letras "parecería" una placa.
  static String? extraer(String texto) {
    final lineas = texto
        .split(RegExp(r'[\r\n]+'))
        // Solo letras y dígitos, en mayúsculas: "wgy-482" y "WGY 482" son lo mismo.
        .map((l) => l.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), ''))
        .where((l) => l.length >= 6)
        .toList();

    for (final linea in lineas) {
      for (var i = 0; i + 6 <= linea.length; i++) {
        final ventana = linea.substring(i, i + 6);
        if (_formato.hasMatch(ventana)) return ventana;
      }
    }
    for (final linea in lineas) {
      for (var i = 0; i + 6 <= linea.length; i++) {
        final corregida = _corregir(linea.substring(i, i + 6));
        if (corregida != null) return corregida;
      }
    }
    return null;
  }

  /// Aplica como máximo una sustitución según lo que debería ir en cada
  /// posición. La última posición admite letra o dígito (carro/moto), así
  /// que no se toca.
  static String? _corregir(String ventana) {
    var cambios = 0;
    final b = StringBuffer();
    for (var i = 0; i < 6; i++) {
      final c = ventana[i];
      String salida = c;
      if (i < 3 && !_esLetra(c)) {
        salida = _aLetra[c] ?? c;
      } else if (i >= 3 && i < 5 && !_esDigito(c)) {
        salida = _aDigito[c] ?? c;
      }
      if (salida != c) cambios++;
      if (cambios > 1) return null;
      b.write(salida);
    }
    final resultado = b.toString();
    return _formato.hasMatch(resultado) ? resultado : null;
  }

  static bool _esLetra(String c) => c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90;
  static bool _esDigito(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

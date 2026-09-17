import 'package:flutter/widgets.dart';

import '../data/parking_repository.dart';
import '../models/vehicle.dart';

/// Validadores reutilizables para los `Form`/`TextFormField` de la app.
///
/// Antes cada pantalla definía su propio `validator:` inline, sin compartir
/// regex ni mensajes (p. ej. el correo solo se comprobaba con
/// `value.contains('@')`, y la placa solo con una longitud mínima). Esto
/// centraliza esas reglas para que todas las pantallas validen igual.
class Validators {
  Validators._();

  /// RFC 5322 simplificado: suficiente para rechazar errores de tecleo
  /// comunes (sin arroba, sin dominio, espacios) sin ser tan estricto como
  /// para rechazar direcciones reales poco comunes.
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Placa colombiana de carro: 3 letras + 3 números (ej. ABC123).
  static final RegExp placaCarroRegex = RegExp(r'^[A-Z]{3}[0-9]{3}$');

  /// Placa colombiana de moto: 3 letras + 2 números + 1 letra final,
  /// obligatoria en placas vigentes (ej. ABC12D). Se acepta también el
  /// formato de 5 caracteres sin la letra final (placas antiguas/desgastadas
  /// que ya circulan, como ya asumía `ParkingRepository`).
  static final RegExp placaMotoRegex = RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]?$');

  /// Correo obligatorio y con formato válido.
  static String? correo(String? value) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(texto)) return 'Ingresa un correo válido';
    return null;
  }

  /// Contraseña para iniciar sesión: solo exige que no esté vacía (la
  /// política de fortaleza se aplica al crearla/cambiarla, no en cada login,
  /// para no bloquear a alguien con una contraseña antigua más corta).
  static String? contrasenaLogin(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  /// Contraseña nueva (registro o restablecimiento): mínimo 8 caracteres con
  /// al menos una mayúscula, una minúscula y un número.
  static String? contrasenaNueva(String? value) {
    final texto = value ?? '';
    if (texto.isEmpty) return 'Ingresa una contraseña';
    if (texto.length < 8) return 'Debe tener al menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(texto)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(texto)) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(texto)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  /// Confirmación de contraseña: no puede quedar vacía ni distinta de la
  /// original (un campo vacío "coincide" trivialmente con otro vacío, así
  /// que la longitud se comprueba aparte). Recibe el controlador (no el
  /// texto ya leído) para comparar siempre contra el valor más reciente al
  /// momento de validar, no contra el que tenía en el build en que se creó
  /// este validador.
  static String? Function(String?) confirmarContrasena(
    TextEditingController original,
  ) {
    return (value) {
      final texto = value ?? '';
      if (texto.isEmpty) return 'Confirma tu contraseña';
      if (texto != original.text) return 'Las contraseñas no coinciden';
      return null;
    };
  }

  /// Placa colombiana según el tipo de vehículo elegido.
  static String? placa(String? value, VehicleType tipo) {
    final normalizada = ParkingRepository.normaliza(value ?? '');
    if (normalizada.isEmpty) return 'Ingresa la placa';
    final regex = tipo == VehicleType.moto ? placaMotoRegex : placaCarroRegex;
    if (!regex.hasMatch(normalizada)) {
      return tipo == VehicleType.moto
          ? 'Formato de placa inválido (ej. ABC12D)'
          : 'Formato de placa inválido (ej. ABC123)';
    }
    return null;
  }

  /// Placa colombiana sin saber aún el tipo de vehículo (p. ej. digitación
  /// manual antes de escanear/consultar): acepta el formato de carro o de
  /// moto, lo que sea que coincida.
  static String? placaCualquierTipo(String? value) {
    final normalizada = ParkingRepository.normaliza(value ?? '');
    if (normalizada.isEmpty) return 'Ingresa la placa';
    if (!placaCarroRegex.hasMatch(normalizada) &&
        !placaMotoRegex.hasMatch(normalizada)) {
      return 'Formato de placa inválido';
    }
    return null;
  }

  /// Campo de texto libre obligatorio, con un tope de longitud razonable
  /// para no dejar guardar algo arbitrariamente largo.
  static String? requerido(String? value, String etiqueta, {int max = 60}) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa $etiqueta';
    if (texto.length > max) return '$etiqueta no puede superar $max caracteres';
    return null;
  }

  /// Descripción/motivo de un reporte: exige un mínimo de detalle (una
  /// palabra suelta no le sirve a quien lo atiende) y un tope máximo.
  static String? textoLargo(
    String? value, {
    String etiqueta = 'una descripción',
    int min = 10,
    int max = 500,
  }) {
    final texto = (value ?? '').trim();
    if (texto.isEmpty) return 'Ingresa $etiqueta';
    if (texto.length < min) return 'Ingresa al menos $min caracteres';
    if (texto.length > max) return 'No puede superar $max caracteres';
    return null;
  }
}

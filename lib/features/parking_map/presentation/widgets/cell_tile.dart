import 'package:flutter/material.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/models/parking_cell.dart';

class _EstiloCelda {
  final Color fondo;
  final Color borde;
  final Color texto;
  final String etiqueta;

  const _EstiloCelda({required this.fondo, required this.borde, required this.texto, required this.etiqueta});
}

const _libre = _EstiloCelda(fondo: Color(0x2639A900), borde: Color(0xFF39A900), texto: Color(0xFFB3E6A1), etiqueta: 'LIBRE');
const _ocupada = _EstiloCelda(fondo: Color(0x29EF4444), borde: Color(0xFFEF4444), texto: Color(0xFFFCA5A5), etiqueta: 'OCUP.');
const _reserva = _EstiloCelda(fondo: Color(0xFF332A10), borde: Color(0xFFF59E0B), texto: Color(0xFFFCD34D), etiqueta: 'RESERVA');
const _mantenimiento = _EstiloCelda(fondo: Color(0xFF23262B), borde: Color(0xFF94A3B8), texto: Color(0xFFCBD5E1), etiqueta: 'MANT.');

/// Una celda del mapa del parqueadero, coloreada según su estado
/// (libre/ocupada/reserva/mantenimiento), igual que en el diseño.
class CellTile extends StatelessWidget {
  final ParkingCell cell;
  final bool seleccionada;
  final double height;
  final VoidCallback? onTap;

  const CellTile({super.key, required this.cell, this.seleccionada = false, this.height = 58, this.onTap});

  _EstiloCelda get _estilo {
    switch (cell.estado) {
      case CellStatus.libre:
        return _libre;
      case CellStatus.ocupada:
        return _ocupada;
      case CellStatus.reserva:
        return _reserva;
      case CellStatus.mantenimiento:
        return _mantenimiento;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estilo = _estilo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: estilo.fondo,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: estilo.borde, width: seleccionada ? 2.5 : 1.5),
          boxShadow: seleccionada ? [BoxShadow(color: estilo.borde.withValues(alpha: 0.45), blurRadius: 0, spreadRadius: 3)] : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cell.codigo, style: AppTextStyles.mono(size: 12, color: estilo.texto)),
            const SizedBox(height: 1),
            Text(
              estilo.etiqueta,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: estilo.texto.withValues(alpha: 0.85), letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

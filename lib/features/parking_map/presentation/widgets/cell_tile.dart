import 'package:flutter/material.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/models/parking_cell.dart';

class _EstiloCelda {
  final Color fondo;
  final Color borde;
  final Color texto;
  final String etiqueta;
  final IconData? icono;

  const _EstiloCelda({required this.fondo, required this.borde, required this.texto, required this.etiqueta, this.icono});
}

const _libre = _EstiloCelda(fondo: Color(0x2639A900), borde: Color(0xFF39A900), texto: Color(0xFFB3E6A1), etiqueta: 'LIBRE');
const _ocupada = _EstiloCelda(
  fondo: Color(0x29EF4444),
  borde: Color(0xFFEF4444),
  texto: Color(0xFFFCA5A5),
  etiqueta: 'OCUP.',
  icono: Icons.directions_car_rounded,
);
const _reserva = _EstiloCelda(
  fondo: Color(0xFF332A10),
  borde: Color(0xFFF59E0B),
  texto: Color(0xFFFCD34D),
  etiqueta: 'RESERVA',
  icono: Icons.bookmark_rounded,
);
const _mantenimiento = _EstiloCelda(
  fondo: Color(0xFF23262B),
  borde: Color(0xFF64748B),
  texto: Color(0xFFCBD5E1),
  etiqueta: 'MANT.',
  icono: Icons.build_rounded,
);

/// Libre en la base, pero apartada por una reserva ajena que empieza pronto:
/// la API no la ofrece para ingresar, así que se ve atenuada y con candado.
const _retenida = _EstiloCelda(
  fondo: Color(0xFF2A2518),
  borde: Color(0x80F59E0B),
  texto: Color(0x99FCD34D),
  etiqueta: 'APART.',
  icono: Icons.lock_clock_rounded,
);

/// La celda que el vehículo tiene reservada: es la que le corresponde.
const _propia = _EstiloCelda(
  fondo: Color(0x33F59E0B),
  borde: Color(0xFFFBBF24),
  texto: Color(0xFFFDE68A),
  etiqueta: 'SUYA',
  icono: Icons.bookmark_added_rounded,
);

/// Borde/insignia de una celda preferencial (PMR, vehículo SENA, ejecutivo).
const _preferencial = Color(0xFF60A5FA);

/// Una celda del mapa del parqueadero, coloreada según su estado
/// (libre/ocupada/reserva/mantenimiento), igual que en el diseño.
class CellTile extends StatelessWidget {
  final ParkingCell cell;
  final bool seleccionada;
  final double height;
  final VoidCallback? onTap;

  const CellTile({super.key, required this.cell, this.seleccionada = false, this.height = 58, this.onTap});

  _EstiloCelda get _estilo {
    if (cell.reservadaParaVehiculo) return _propia;
    switch (cell.estado) {
      case CellStatus.libre:
        return cell.retenidaPorReserva ? _retenida : _libre;
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
    final insignia = cell.usabilidad.insignia;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: height,
        decoration: BoxDecoration(
          color: estilo.fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: seleccionada ? Colors.white : estilo.borde, width: seleccionada ? 2.2 : 1.4),
          boxShadow: seleccionada ? [BoxShadow(color: estilo.borde.withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 1)] : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (estilo.icono != null) ...[
                    Icon(estilo.icono, size: 13, color: estilo.texto.withValues(alpha: 0.9)),
                    const SizedBox(height: 1),
                  ],
                  Text(cell.codigo, style: AppTextStyles.mono(size: 12, color: estilo.texto)),
                  if (estilo.icono == null) ...[
                    const SizedBox(height: 1),
                    Text(
                      estilo.etiqueta,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: estilo.texto.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (insignia.isNotEmpty)
              Positioned(
                top: 3,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _preferencial.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _preferencial.withValues(alpha: 0.8), width: 1),
                  ),
                  child: Text(
                    insignia,
                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: _preferencial, letterSpacing: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

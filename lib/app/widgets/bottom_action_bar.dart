import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Barra blanca fija al pie de la pantalla para el botón principal de un
/// flujo (Verificar, Confirmar salida, Denegar…). Respeta el área segura
/// inferior y proyecta una sombra suave hacia arriba.
class BottomActionBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BottomActionBar({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(22, 16, 22, 16)});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppColors.topShadow,
      ),
      padding: padding.add(EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 8)),
      child: child,
    );
  }
}

/// Asa de arrastre de las hojas inferiores.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Barra superior de las pantallas claras: botón de volver (opcional),
/// título grande, subtítulo y un widget al final (acción, filtro…).
///
/// Va dentro del [SafeArea] de la página. Para que los iconos de la barra
/// de estado sean oscuros, la página se envuelve en [DarkStatusBarIcons].
class PageTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final bool large;

  const PageTopBar({super.key, required this.title, this.subtitle, this.showBack = false, this.trailing, this.large = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      child: Row(
        children: [
          if (showBack) ...[const BackCircleButton(), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: large ? AppTextStyles.heading2 : AppTextStyles.heading3.copyWith(fontSize: 18), overflow: TextOverflow.ellipsis, maxLines: 1),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Envuelve una pantalla de fondo claro para que los iconos de la barra de
/// estado se dibujen oscuros. Debe abarcar el Scaffold completo (no solo la
/// cabecera): Flutter decide el estilo mirando qué región cubre el borde
/// superior de la pantalla.
class DarkStatusBarIcons extends StatelessWidget {
  final Widget child;
  const DarkStatusBarIcons({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: child);
  }
}

/// Botón circular blanco con flecha de volver.
class BackCircleButton extends StatelessWidget {
  final Color? color;
  final Color? background;
  final Color? borderColor;
  final VoidCallback? onTap;

  const BackCircleButton({super.key, this.color, this.background, this.borderColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.white,
      shape: CircleBorder(side: BorderSide(color: borderColor ?? AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: SizedBox(width: 42, height: 42, child: Icon(Icons.arrow_back_rounded, size: 21, color: color ?? AppColors.textPrimary)),
      ),
    );
  }
}

/// Botón cuadrado pequeño (40x40) para acciones de cabecera en pantallas
/// claras, p. ej. "+" para registrar un vehículo o el filtro del historial.
class TopBarActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const TopBarActionButton({super.key, required this.icon, this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: filled ? AppColors.primaryGradient : null,
        color: filled ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: AppColors.border),
        boxShadow: filled ? AppColors.primaryShadow : AppColors.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 22, color: filled ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }
}

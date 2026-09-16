import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum ChipTone { success, neutral, danger, warning, info }

/// Píldora de estado con un punto de color: "Dentro", "Salió", "Novedad",
/// "Vigente", etc.
class StatusChip extends StatelessWidget {
  final String label;
  final ChipTone tone;
  final bool showDot;
  final bool outlined;

  const StatusChip({super.key, required this.label, this.tone = ChipTone.neutral, this.showDot = true, this.outlined = false});

  Color get _bg {
    switch (tone) {
      case ChipTone.success:
        return AppColors.primarySoft;
      case ChipTone.neutral:
        return AppColors.neutralSoft;
      case ChipTone.danger:
        return AppColors.dangerSoft;
      case ChipTone.warning:
        return AppColors.warningSoft;
      case ChipTone.info:
        return AppColors.infoSoft;
    }
  }

  Color get _fg {
    switch (tone) {
      case ChipTone.success:
        return AppColors.primaryDark;
      case ChipTone.neutral:
        return AppColors.textSecondary;
      case ChipTone.danger:
        return AppColors.dangerDarker;
      case ChipTone.warning:
        return AppColors.warningDark;
      case ChipTone.info:
        return AppColors.info;
    }
  }

  Color get _dot {
    switch (tone) {
      case ChipTone.success:
        return AppColors.primary;
      case ChipTone.neutral:
        return AppColors.textPlaceholder;
      case ChipTone.danger:
        return AppColors.danger;
      case ChipTone.warning:
        return AppColors.warning;
      case ChipTone.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: _dot.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: _dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _fg, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

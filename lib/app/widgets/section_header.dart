import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Título de sección en mayúsculas (overline) con una acción opcional a
/// la derecha, p. ej. "ÚLTIMOS MOVIMIENTOS · Ver todo ›".
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.overline, overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!, style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primaryDark),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

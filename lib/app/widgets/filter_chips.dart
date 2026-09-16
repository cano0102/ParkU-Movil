import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Fila horizontal de filtros tipo píldora con una única opción activa.
class FilterChipsRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const FilterChipsRow({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: EdgeInsets.only(right: option != options.last ? 8 : 0),
              child: _Chip(label: option, selected: option == selected, onTap: () => onSelected(option)),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        boxShadow: selected ? AppColors.primaryShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppNavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Barra de navegación inferior compartida por el guarda y el conductor:
/// fondo blanco flotante con esquinas superiores redondeadas y una
/// "píldora" animada detrás del icono activo.
class AppBottomNav extends StatelessWidget {
  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.items, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppColors.topShadow,
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset > 0 ? bottomInset : 10),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = selectedIndex == i;
          final color = selected ? AppColors.primaryDark : AppColors.textPlaceholder;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(i),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: selected ? 56 : 40,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primarySoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

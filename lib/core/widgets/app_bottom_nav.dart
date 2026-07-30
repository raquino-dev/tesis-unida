import 'package:flutter/material.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_theme_extension.dart';

class AppBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom navigation con 5 tabs; el botón de "Añadir" (índice central) tiene
/// mayor protagonismo visual mediante un contenedor elevado en Scampi.
class AppBottomNav extends StatelessWidget {
  static const double _verticalPadding = 10;
  static const double _fabSize = 52;

  /// Distancia entre el borde inferior de la pantalla y el centro vertical
  /// del botón "Añadir", usada por overlays (como [AppSpeedDialFab]) para
  /// alinearse a la misma altura del botón que los despliega.
  static double fabCenterFromBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom +
        _verticalPadding +
        (_fabSize / 2);
  }

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;
  final int addIndex;
  final bool centerExpanded;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.addIndex = 2,
    this.centerExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: AppShadows.card(isDark),
      ),
      padding: const EdgeInsets.only(
        top: _verticalPadding,
        bottom: _verticalPadding,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;

            if (index == addIndex) {
              return GestureDetector(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _fabSize,
                      height: _fabSize,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.glow(colors.primary),
                      ),
                      child: AnimatedRotation(
                        turns: centerExpanded ? 0.125 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          item.activeIcon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final color = selected ? colors.primary : colors.textMuted;
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

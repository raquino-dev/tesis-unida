import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_theme_extension.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onRemove;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.accentColor,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = accentColor ?? colors.primary;
    final bg = selected ? accent : colors.surfaceElevated;
    final fg = selected ? Colors.white : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.pillRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.close_rounded, size: 14, color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

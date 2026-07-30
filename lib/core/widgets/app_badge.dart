import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_theme_extension.dart';

enum AppBadgeTone { neutral, success, warning, error, info, premium }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    late Color bg;
    late Color fg;
    switch (tone) {
      case AppBadgeTone.neutral:
        bg = colors.surfaceElevated;
        fg = colors.textSecondary;
        break;
      case AppBadgeTone.success:
        bg = colors.successBg;
        fg = colors.success;
        break;
      case AppBadgeTone.warning:
        bg = colors.warningBg;
        fg = colors.warning;
        break;
      case AppBadgeTone.error:
        bg = colors.errorBg;
        fg = colors.error;
        break;
      case AppBadgeTone.info:
        bg = colors.infoBg;
        fg = colors.info;
        break;
      case AppBadgeTone.premium:
        bg = colors.primary.withValues(alpha: 0.18);
        fg = colors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

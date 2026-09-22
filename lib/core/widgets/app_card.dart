import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extension.dart';

enum AppCardElevation { surface, elevated }

/// Superficie compartida de las secciones de Finanza.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AppCardElevation elevation;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.elevation = AppCardElevation.surface,
    this.onTap,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = elevation == AppCardElevation.surface
        ? colors.surface
        : colors.surfaceElevated;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: AppRadius.mdRadius,
          border:
              border ?? Border.all(color: colors.border.withValues(alpha: 0.7)),
          boxShadow: AppShadows.subtle(isDark),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

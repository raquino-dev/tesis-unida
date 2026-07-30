import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extension.dart';

enum AppCardElevation { surface, elevated }

/// Card base de la app. Usa las superficies Ebony Clay / Martinique según
/// [elevation] para crear separación de capas sin romper la estética oscura.
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
          borderRadius: AppRadius.lgRadius,
          border: border,
          boxShadow: AppShadows.subtle(isDark),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

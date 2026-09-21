import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_theme_extension.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final disabled = onPressed == null || isLoading;

    Color bg;
    Color fg;
    Border? border;
    switch (variant) {
      case AppButtonVariant.primary:
        bg = colors.primary;
        fg = Colors.white;
        border = null;
        break;
      case AppButtonVariant.secondary:
        bg = colors.surfaceElevated;
        fg = colors.textPrimary;
        border = Border.all(color: colors.border);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = colors.primary;
        border = null;
        break;
      case AppButtonVariant.danger:
        bg = colors.errorBg;
        fg = colors.error;
        border = Border.all(color: colors.error.withValues(alpha: 0.4));
        break;
    }

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled && !isLoading ? 0.5 : 1,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.pillRadius,
          child: Ink(
            decoration: BoxDecoration(
              color: variant == AppButtonVariant.primary ? null : bg,
              gradient: variant == AppButtonVariant.primary
                  ? LinearGradient(
                      colors: [colors.primary, colors.primaryVariant],
                    )
                  : null,
              borderRadius: AppRadius.pillRadius,
              border: border,
            ),
            child: InkWell(
              onTap: disabled ? null : onPressed,
              borderRadius: AppRadius.pillRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

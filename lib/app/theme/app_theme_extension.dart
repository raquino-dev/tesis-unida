import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tokens semánticos accesibles vía `Theme.of(context).extension<AppSemanticColors>()`.
/// Permiten a los widgets referirse a "surfaceElevated" o "success" sin
/// acoplarse a los nombres de la paleta de marca.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color primaryVariant;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;

  const AppSemanticColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.primaryVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
  });

  static const dark = AppSemanticColors(
    background: AppColors.mirage,
    surface: AppColors.ebonyClay,
    surfaceElevated: AppColors.martinique,
    primary: AppColors.scampi,
    primaryVariant: AppColors.comet,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    border: AppColors.martinique,
    success: AppColors.success,
    successBg: AppColors.successBg,
    warning: AppColors.warning,
    warningBg: AppColors.warningBg,
    error: AppColors.error,
    errorBg: AppColors.errorBg,
    info: AppColors.info,
    infoBg: AppColors.infoBg,
  );

  static const light = AppSemanticColors(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    primary: AppColors.emerald,
    primaryVariant: AppColors.forest,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    border: AppColors.lightBorder,
    success: AppColors.success,
    successBg: Color(0xFFDCEFE7),
    warning: AppColors.warning,
    warningBg: Color(0xFFF3E7D2),
    error: AppColors.error,
    errorBg: Color(0xFFF3DCDE),
    info: AppColors.info,
    infoBg: Color(0xFFDCE6F0),
  );

  @override
  AppSemanticColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? primary,
    Color? primaryVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? error,
    Color? errorBg,
    Color? info,
    Color? infoBg,
  }) {
    return AppSemanticColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppSemanticColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      primary: l(primary, other.primary),
      primaryVariant: l(primaryVariant, other.primaryVariant),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      border: l(border, other.border),
      success: l(success, other.success),
      successBg: l(successBg, other.successBg),
      warning: l(warning, other.warning),
      warningBg: l(warningBg, other.warningBg),
      error: l(error, other.error),
      errorBg: l(errorBg, other.errorBg),
      info: l(info, other.info),
      infoBg: l(infoBg, other.infoBg),
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}

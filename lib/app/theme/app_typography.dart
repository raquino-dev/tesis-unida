import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Escala tipográfica centralizada. Alto contraste, jerarquía fuerte.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color primary, Color secondary, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Estilo especial para métricas financieras grandes (saldo, montos destacados).
  static const TextStyle metricXL = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: AppColors.textPrimaryDark,
  );

  static const TextStyle metricLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle metricMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
}

import 'package:flutter/material.dart';

/// Sombras discretas. La profundidad se logra sobre todo por contraste de
/// capas (Mirage -> Ebony Clay -> Martinique), la sombra solo refuerza.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> subtle(bool isDark) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> glow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.25),
        blurRadius: 30,
        spreadRadius: -6,
      ),
    ];
  }
}

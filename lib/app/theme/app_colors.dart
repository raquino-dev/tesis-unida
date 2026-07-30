import 'package:flutter/material.dart';

/// Paleta Midnight Cat — identidad visual dark-first de la app.
class AppColors {
  AppColors._();

  // Paleta base Midnight Cat
  static const Color mirage = Color(0xFF121226);
  static const Color ebonyClay = Color(0xFF21213B);
  static const Color martinique = Color(0xFF363659);
  static const Color comet = Color(0xFF505077);
  static const Color scampi = Color(0xFF6868A6);

  // Texto
  static const Color textPrimaryDark = Color(0xFFF4F4FA);
  static const Color textSecondaryDark = Color(0xFFC7C7DD);
  static const Color textMutedDark = Color(0xFF9A9AB8);

  static const Color textPrimaryLight = Color(0xFF14142B);
  static const Color textSecondaryLight = Color(0xFF3D3D5C);
  static const Color textMutedLight = Color(0xFF6B6B8D);

  // Estados funcionales (desaturados, sobrios)
  static const Color success = Color(0xFF3FA37A);
  static const Color successBg = Color(0xFF1B2E2A);
  static const Color warning = Color(0xFFC79A4B);
  static const Color warningBg = Color(0xFF322A1B);
  static const Color error = Color(0xFFB0555A);
  static const Color errorBg = Color(0xFF321E22);
  static const Color info = Color(0xFF5C86B0);
  static const Color infoBg = Color(0xFF1B2530);

  // Modo claro — versión sobria de la misma marca
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFE9E9F3);
  static const Color lightBorder = Color(0xFFD8D8E6);
}

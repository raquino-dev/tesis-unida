import 'package:flutter/material.dart';

/// Paleta de Finanza. Los nombres históricos se conservan para las
/// ilustraciones existentes; los widgets deben usar AppSemanticColors.
class AppColors {
  AppColors._();

  static const Color forest = Color(0xFF00583B);
  static const Color emerald = Color(0xFF008A59);
  static const Color mint = Color(0xFFE8FAF2);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF5FFFA);
  static const Color ink = Color(0xFF122439);

  static const Color mirage = Color(0xFF10251F);
  static const Color ebonyClay = Color(0xFF17382E);
  static const Color martinique = Color(0xFF245343);
  static const Color comet = Color(0xFF2D986B);
  static const Color scampi = emerald;

  // Texto
  static const Color textPrimaryDark = Color(0xFFF5FFF9);
  static const Color textSecondaryDark = Color(0xFFCCE6D9);
  static const Color textMutedDark = Color(0xFFA2C8B5);

  static const Color textPrimaryLight = ink;
  static const Color textSecondaryLight = Color(0xFF445569);
  static const Color textMutedLight = Color(0xFF718094);

  // Estados funcionales (desaturados, sobrios)
  static const Color success = Color(0xFF009B65);
  static const Color successBg = Color(0xFF183B2D);
  static const Color warning = Color(0xFFE5A12C);
  static const Color warningBg = Color(0xFF42351E);
  static const Color error = Color(0xFFE63E57);
  static const Color errorBg = Color(0xFF4B252C);
  static const Color info = Color(0xFF2789E5);
  static const Color infoBg = Color(0xFF1C374C);

  // Modo claro — versión sobria de la misma marca
  static const Color lightBackground = canvas;
  static const Color lightSurface = paper;
  static const Color lightSurfaceElevated = Color(0xFFEAF8F2);
  static const Color lightBorder = Color(0xFFDCEAE5);
}

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Fondo geométrico abstracto de marca: círculos superpuestos y arcos
/// gruesos en tonos de marca, con opacidad baja para no saturar la UI.
class AbstractBackdrop extends StatelessWidget {
  final double height;
  final Color accent;

  const AbstractBackdrop({
    super.key,
    this.height = 240,
    this.accent = AppColors.scampi,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _circle(220, accent.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 30,
            right: 40,
            child: _ring(120, accent.withValues(alpha: 0.35), 10),
          ),
          Positioned(
            top: -40,
            left: -70,
            child: _circle(160, AppColors.martinique.withValues(alpha: 0.5)),
          ),
          Positioned(
            bottom: -60,
            left: 60,
            child: _circle(90, AppColors.comet.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _ring(double size, Color color, double strokeWidth) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }
}

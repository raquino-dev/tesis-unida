import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

/// Variante visual de la ilustración abstracta de cada página del
/// onboarding. Cada una usa la misma paleta Midnight Cat pero compone
/// círculos, arcos y líneas curvas de forma distinta para diferenciar
/// visualmente cada mensaje sin depender de imágenes reales.
enum OnboardingIllustrationVariant { overview, speed, clarity }

/// Ilustración geométrica abstracta para el onboarding. Reemplaza el fondo
/// genérico anterior por una composición distinta por página (arcos tipo
/// gráfico, líneas de velocidad, anillos concéntricos), manteniendo el
/// mismo color de acento, tamaño e ícono central que ya tenía cada página.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingIllustrationVariant variant;
  final Color accent;
  final double height;

  const OnboardingIllustration({
    super.key,
    required this.variant,
    required this.accent,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: switch (variant) {
          OnboardingIllustrationVariant.overview => _OverviewPainter(
            accent: accent,
          ),
          OnboardingIllustrationVariant.speed => _SpeedPainter(accent: accent),
          OnboardingIllustrationVariant.clarity => _ClarityPainter(
            accent: accent,
          ),
        },
      ),
    );
  }
}

/// Arcos concéntricos tipo "gráfico de progreso", con puntos dispersos,
/// evocando control y visión general de las finanzas.
class _OverviewPainter extends CustomPainter {
  final Color accent;
  const _OverviewPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);

    final outerArc = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 108),
      -2.6,
      3.4,
      false,
      outerArc,
    );

    final innerArc = Paint()
      ..color = AppColors.comet.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 78),
      0.4,
      2.6,
      false,
      innerArc,
    );

    final fillCircle = Paint()
      ..color = AppColors.martinique.withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.18),
      26,
      fillCircle,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.14),
      16,
      fillCircle,
    );

    final dot = Paint()..color = accent.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.62), 5, dot);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.72), 4, dot);
  }

  @override
  bool shouldRepaint(covariant _OverviewPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Líneas curvas diagonales que sugieren velocidad y fluidez, con un anillo
/// grueso partido evocando movimiento rápido.
class _SpeedPainter extends CustomPainter {
  final Color accent;
  const _SpeedPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);

    final ring = Paint()
      ..color = accent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 100),
      -2.2,
      4.2,
      false,
      ring,
    );

    final streak = Paint()
      ..color = AppColors.comet.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final path1 = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.62,
        size.height * 0.68,
      );
    canvas.drawPath(path1, streak);

    final streak2 = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.92)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.74,
        size.width * 0.72,
        size.height * 0.84,
      );
    canvas.drawPath(path2, streak2);

    final fillCircle = Paint()
      ..color = AppColors.martinique.withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.22),
      20,
      fillCircle,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

/// Anillos concéntricos tipo escudo, evocando protección y claridad.
class _ClarityPainter extends CustomPainter {
  final Color accent;
  const _ClarityPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);

    final ringOuter = Paint()
      ..color = AppColors.martinique.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, 100, ringOuter);

    final ringMid = Paint()
      ..color = AppColors.comet.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, 74, ringMid);

    final arc = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 100),
      -1.7,
      2.1,
      false,
      arc,
    );

    final dot = Paint()..color = accent.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.24), 6, dot);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.78), 5, dot);
  }

  @override
  bool shouldRepaint(covariant _ClarityPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

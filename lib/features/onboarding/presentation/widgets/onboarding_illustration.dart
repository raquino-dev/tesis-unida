import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

enum OnboardingIllustrationVariant { overview, speed, clarity }

/// Ilustraciones vectoriales de las tres ideas del onboarding.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.variant,
    this.height = 310,
  });

  final OnboardingIllustrationVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 340,
          height: 310,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 35,
                top: 17,
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFE1F8F0)],
                      stops: [0.24, 1],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _IllustrationAccents(variant)),
              ),
              if (variant == OnboardingIllustrationVariant.overview)
                const _OverviewIllustration(),
              if (variant == OnboardingIllustrationVariant.speed)
                const _SpeedIllustration(),
              if (variant == OnboardingIllustrationVariant.clarity)
                const _ClarityIllustration(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewIllustration extends StatelessWidget {
  const _OverviewIllustration();

  @override
  Widget build(BuildContext context) {
    const barColors = [
      Color(0xFFBFF4DC),
      Color(0xFF8DE6BD),
      Color(0xFF5BD4A0),
      Color(0xFF26AD79),
      AppColors.emerald,
    ];
    const heights = [22.0, 38.0, 55.0, 72.0, 92.0];
    return Stack(
      children: [
        Positioned(
          left: 77,
          top: 102,
          child: _IllustrationCard(
            width: 188,
            height: 155,
            child: Stack(
              children: [
                Positioned(
                  left: 19,
                  top: 27,
                  child: SizedBox(
                    width: 95,
                    height: 58,
                    child: CustomPaint(painter: _GrowthArrowPainter()),
                  ),
                ),
                Positioned(
                  bottom: 19,
                  left: 21,
                  right: 21,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < heights.length; i++)
                        Container(
                          width: 19,
                          height: heights[i],
                          decoration: BoxDecoration(
                            color: barColors[i],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: 45,
          child: Container(
            width: 75,
            height: 75,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFD8FAE9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.09),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Text(
              '\$',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 37,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedIllustration extends StatelessWidget {
  const _SpeedIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 108,
          top: 55,
          child: _IllustrationCard(
            width: 125,
            height: 190,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 39, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReceiptLine(width: 76, height: 9),
                  const SizedBox(height: 13),
                  _ReceiptLine(width: 58, height: 8),
                  const SizedBox(height: 12),
                  _ReceiptLine(width: 42, height: 8),
                  const SizedBox(height: 12),
                  _ReceiptLine(width: 54, height: 8),
                  const SizedBox(height: 12),
                  _ReceiptLine(width: 69, height: 8),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 99,
          top: 46,
          child: SizedBox(
            width: 143,
            height: 209,
            child: CustomPaint(painter: _ScanCornersPainter()),
          ),
        ),
        Positioned(
          right: 34,
          top: 124,
          child: Container(
            width: 89,
            height: 89,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE9FFF4),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.09),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 50,
              color: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClarityIllustration extends StatelessWidget {
  const _ClarityIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 73,
          top: 48,
          child: Container(
            width: 194,
            height: 194,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5FFFA),
              border: Border.all(color: const Color(0xFFC8EEE0), width: 7),
            ),
          ),
        ),
        Positioned(
          left: 93,
          top: 68,
          child: Container(
            width: 154,
            height: 154,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 92,
                  color: AppColors.emerald,
                ),
                const Positioned(
                  top: 59,
                  child: Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          top: 28,
          left: 2,
          child: _FloatingLabel(
            icon: Icons.lightbulb_rounded,
            text: 'Mejores\nhábitos',
          ),
        ),
        const Positioned(
          top: 27,
          right: 0,
          child: _FloatingLabel(
            icon: Icons.bar_chart_rounded,
            text: 'Más\nclaridad',
          ),
        ),
        const Positioned(
          right: 4,
          bottom: 18,
          child: _FloatingLabel(
            icon: Icons.favorite_rounded,
            text: 'Tranquilidad\nfinanciera',
          ),
        ),
      ],
    );
  }
}

class _FloatingLabel extends StatelessWidget {
  const _FloatingLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 21, color: AppColors.emerald),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              height: 1.15,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.11),
            blurRadius: 23,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFD7E1E2),
      borderRadius: BorderRadius.circular(99),
    ),
  );
}

class _IllustrationAccents extends CustomPainter {
  const _IllustrationAccents(this.variant);

  final OnboardingIllustrationVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    if (variant == OnboardingIllustrationVariant.overview) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 139),
        math.pi * 1.10,
        0.85,
        false,
        stroke,
      );
    } else if (variant == OnboardingIllustrationVariant.speed) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 137),
        math.pi * 0.08,
        1.12,
        false,
        stroke,
      );
      final line = Paint()
        ..color = AppColors.emerald.withValues(alpha: 0.45)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = 142.0 + i * 27;
        canvas.drawLine(Offset(23, y), Offset(77 - i * 7, y), line);
      }
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 134),
        -math.pi / 2,
        math.pi * 0.77,
        false,
        stroke,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 134),
        math.pi * 0.40,
        math.pi * 0.34,
        false,
        stroke,
      );
    }

    final dots = variant == OnboardingIllustrationVariant.overview
        ? [(286.0, 76.0, 11.0), (47.0, 167.0, 6.0), (293.0, 232.0, 19.0)]
        : variant == OnboardingIllustrationVariant.speed
        ? [(60.0, 53.0, 6.0), (37.0, 255.0, 11.0)]
        : [(36.0, 161.0, 17.0), (305.0, 223.0, 6.0)];
    for (final (x, y, radius) in dots) {
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = AppColors.emerald.withValues(alpha: radius > 10 ? .3 : .8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationAccents oldDelegate) =>
      oldDelegate.variant != variant;
}

class _GrowthArrowPainter extends CustomPainter {
  const _GrowthArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(4, size.height - 6)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.78,
        size.width - 11,
        9,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width - 29, 9),
      Offset(size.width - 11, 9),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 11, 9),
      Offset(size.width - 11, 26),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanCornersPainter extends CustomPainter {
  const _ScanCornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const length = 20.0;
    for (final corner in [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final x = corner.dx;
      final y = corner.dy;
      final directionX = x == 0 ? 1.0 : -1.0;
      final directionY = y == 0 ? 1.0 : -1.0;
      final path = Path()
        ..moveTo(x, y + length * directionY)
        ..lineTo(x, y)
        ..lineTo(x + length * directionX, y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

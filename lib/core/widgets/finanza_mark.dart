import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Isotipo de hoja construido en Flutter para que conserve nitidez a cualquier
/// densidad de pantalla sin depender de los PNG de referencia.
class FinanzaMark extends StatelessWidget {
  final double size;
  const FinanzaMark({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LeafPainter()),
  );
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Path()
      ..moveTo(size.width * .07, size.height * .91)
      ..cubicTo(
        size.width * .04,
        size.height * .35,
        size.width * .37,
        size.height * .06,
        size.width * .95,
        size.height * .05,
      )
      ..cubicTo(
        size.width * .95,
        size.height * .58,
        size.width * .64,
        size.height * .95,
        size.width * .07,
        size.height * .91,
      )
      ..close();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF8AE4AE), AppColors.emerald, AppColors.forest],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FinanzaWordmark extends StatelessWidget {
  final bool compact;
  const FinanzaWordmark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FinanzaMark(size: compact ? 32 : 46),
      SizedBox(width: compact ? 8 : 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Finanza',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: compact ? 22 : 31,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          if (!compact)
            Text(
              'Pequeños hábitos, grandes logros.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    ],
  );
}

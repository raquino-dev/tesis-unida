import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme_extension.dart';

class OcrProcessingIllustration extends StatefulWidget {
  const OcrProcessingIllustration({super.key});

  @override
  State<OcrProcessingIllustration> createState() =>
      _OcrProcessingIllustrationState();
}

class _OcrProcessingIllustrationState extends State<OcrProcessingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Escaneando el comprobante',
      child: SizedBox.square(
        dimension: 264,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ReceiptScanPainter(
                  scan: _scan,
                  primary: colors.primary,
                  border: colors.border,
                ),
              ),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14005540),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_rounded,
                color: colors.primary,
                size: 35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptScanPainter extends CustomPainter {
  final Animation<double> scan;
  final Color primary;
  final Color border;

  _ReceiptScanPainter({
    required this.scan,
    required this.primary,
    required this.border,
  }) : super(repaint: scan);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 280);

    final background = Paint()..color = primary.withValues(alpha: 0.07);
    canvas.drawCircle(const Offset(140, 140), 112, background);

    final receipt = Path()..moveTo(92, 58);
    for (var i = 0; i < 9; i++) {
      receipt.lineTo(92 + i * 11, i.isEven ? 58 : 67);
    }
    receipt.lineTo(180, 218);
    for (var i = 8; i >= 0; i--) {
      receipt.lineTo(92 + i * 11, i.isEven ? 218 : 209);
    }
    receipt.close();
    canvas.drawShadow(receipt, const Color(0x22007156), 12, false);
    canvas.drawPath(receipt, Paint()..color = Colors.white);

    final detail = Paint()
      ..color = border.withValues(alpha: 0.95)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final line in <(double, double, double)>[
      (87, 111, 169),
      (103, 111, 153),
      (119, 111, 166),
      (161, 111, 166),
      (177, 111, 170),
      (193, 111, 154),
    ]) {
      canvas.drawLine(
        Offset(line.$2, line.$1),
        Offset(line.$3, line.$1),
        detail,
      );
    }

    final bracket = Paint()
      ..color = primary
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final path in [
      Path()
        ..moveTo(71, 79)
        ..lineTo(71, 64)
        ..lineTo(87, 64),
      Path()
        ..moveTo(193, 64)
        ..lineTo(209, 64)
        ..lineTo(209, 79),
      Path()
        ..moveTo(71, 201)
        ..lineTo(71, 216)
        ..lineTo(87, 216),
      Path()
        ..moveTo(193, 216)
        ..lineTo(209, 216)
        ..lineTo(209, 201),
    ]) {
      canvas.drawPath(path, bracket);
    }

    final scanY = 101 + 78 * scan.value;
    final glow = Paint()
      ..color = primary.withValues(alpha: 0.28)
      ..strokeWidth = 13
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawLine(Offset(50, scanY), Offset(230, scanY), glow);
    final beam = Paint()
      ..shader = LinearGradient(
        colors: [
          primary.withValues(alpha: 0),
          primary.withValues(alpha: 0.85),
          primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(44, scanY, 192, 1))
      ..strokeWidth = 3;
    canvas.drawLine(Offset(44, scanY), Offset(236, scanY), beam);

    final dots = Paint()..color = primary.withValues(alpha: 0.26);
    canvas.drawCircle(const Offset(37, 119), 5, dots);
    canvas.drawCircle(const Offset(225, 34), 6, dots);
    canvas.drawCircle(const Offset(246, 190), 9, dots);
    canvas.drawCircle(const Offset(50, 214), 5, dots);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReceiptScanPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.border != border;
}

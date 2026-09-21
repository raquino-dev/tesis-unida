import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/finanza_mark.dart';

/// Presentación de marca que precede al onboarding solo en la primera apertura.
class FirstLaunchSplashScreen extends StatefulWidget {
  const FirstLaunchSplashScreen({super.key});

  @override
  State<FirstLaunchSplashScreen> createState() =>
      _FirstLaunchSplashScreenState();
}

class _FirstLaunchSplashScreenState extends State<FirstLaunchSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  Timer? _nextPage;

  @override
  void initState() {
    super.initState();
    _nextPage = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go(AppRoutes.onboarding);
    });
  }

  @override
  void dispose() {
    _nextPage?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    final rise = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: CustomPaint(painter: _SplashWavesPainter()),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, -0.2),
              child: FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: rise,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FinanzaMark(size: 78),
                      const SizedBox(height: 14),
                      const Text(
                        'Finanza',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pequeños hábitos,\ngrandes logros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWavesPainter extends CustomPainter {
  const _SplashWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mint = Path()
      ..moveTo(0, size.height * 0.28)
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.36,
        size.width * 0.26,
        size.height * 0.63,
        size.width * 0.35,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      mint,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE5FFF2), Color(0xFFBDF2D4)],
        ).createShader(Offset.zero & size),
    );

    final pale = Path()
      ..moveTo(size.width * 0.53, size.height)
      ..cubicTo(
        size.width * 0.64,
        size.height * 0.36,
        size.width * 0.82,
        size.height * 0.12,
        size.width,
        size.height * 0.12,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(pale, Paint()..color = const Color(0xFFE0FFF0));

    final green = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..cubicTo(
        size.width * 0.53,
        size.height * 0.56,
        size.width * 0.75,
        size.height * 0.84,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      green,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF78DDA8), AppColors.emerald],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_state_view.dart';
import 'score_viewmodel.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoreViewModelProvider);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Score financiero')),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(
          message: message,
          onRetry: ref.read(scoreViewModelProvider.notifier).load,
        ),
        empty: () => const AppEmptyState(
          title: 'Sin score disponible',
          message: 'Necesitamos más movimientos para calcular tu score.',
        ),
        success: (score) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _ScoreGaugePainter(
                    score: score.score,
                    trackColor: colors.surfaceElevated,
                    progressColor: colors.primary,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score.status,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu score es una guía, no una calificación personal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(title: 'Lo que suma'),
            const SizedBox(height: AppSpacing.sm),
            ...score.positiveFactors.map(
              (f) => _FactorTile(text: f, positive: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Lo que resta'),
            const SizedBox(height: AppSpacing.sm),
            ...score.negativeFactors.map(
              (f) => _FactorTile(text: f, positive: false),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Historial mensual'),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: score.history.map((h) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.monthYear(h.month),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${h.score}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Recomendaciones'),
            const SizedBox(height: AppSpacing.sm),
            ...score.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  elevation: AppCardElevation.elevated,
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactorTile extends StatelessWidget {
  final String text;
  final bool positive;
  const _FactorTile({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = positive ? colors.success : colors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        elevation: AppCardElevation.elevated,
        child: Row(
          children: [
            Icon(
              positive
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final int score;
  final Color trackColor;
  final Color progressColor;

  _ScoreGaugePainter({
    required this.score,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 3.14159 * 0.75;
    const sweepAngle = 3.14159 * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (score / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) =>
      oldDelegate.score != score;
}

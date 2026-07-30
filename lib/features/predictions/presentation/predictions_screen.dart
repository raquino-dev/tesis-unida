import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_state_view.dart';
import 'prediction_viewmodel.dart';
import '../../subscription/domain/subscription_entity.dart';
import '../../subscription/presentation/premium_gate.dart';

class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(predictionViewModelProvider);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Predicciones')),
      body: PremiumGate(
        capability: PremiumCapability.predictions,
        child: state.when(
          loading: () => const AppLoadingState(),
          error: (message) => AppErrorState(
            message: message,
            onRetry: ref.read(predictionViewModelProvider.notifier).load,
          ),
          empty: () => const AppEmptyState(
            title: 'Todavía no hay suficientes datos',
            message:
                'Registrá más movimientos para que podamos generar una predicción confiable.',
          ),
          success: (prediction) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              if (prediction.isPreliminary) ...[
                const AppCard(
                  elevation: AppCardElevation.elevated,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.science_outlined),
                    title: Text('Proyección preliminar'),
                    subtitle: Text(
                      'Hay menos de 3 meses de historial. La precisión mejorará al registrar más movimientos.',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riesgo financiero',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppBadge(
                          label: prediction.riskLevel,
                          tone: AppBadgeTone.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gasto proyectado',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  prediction.projectedExpense,
                                ),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance proyectado',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(
                                  prediction.projectedBalance,
                                ),
                                style: TextStyle(
                                  color: colors.success,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Con base en tus últimos movimientos, estimamos que tu categoría con mayor crecimiento será ${prediction.topGrowthCategory}. Esta predicción se basa en patrones recientes, no es una garantía.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(title: 'Predicción por categoría'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: prediction.categoryPredictions.map((c) {
                    final up = c.variation >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.categoryName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatCompact(c.projectedAmount),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            up
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 14,
                            color: up ? colors.warning : colors.success,
                          ),
                          Text(
                            '${(c.variation.abs() * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: up ? colors.warning : colors.success,
                              fontSize: 12,
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
              const AppSectionHeader(title: 'Historial de predicciones'),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  children: prediction.history.map((h) {
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
                            'Proyectado ${CurrencyFormatter.formatCompact(h.projected)}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Real ${CurrencyFormatter.formatCompact(h.actual)}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

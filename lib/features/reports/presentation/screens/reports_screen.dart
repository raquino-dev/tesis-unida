import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/report_entity.dart';
import '../viewmodels/report_viewmodel.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  String _rangeLabel(ReportRange r) {
    switch (r) {
      case ReportRange.week:
        return 'Semana';
      case ReportRange.month:
        return 'Mes';
      case ReportRange.quarter:
        return 'Trimestre';
      case ReportRange.year:
        return 'Año';
      case ReportRange.custom:
        return 'Personalizado';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportViewModelProvider);
    final viewModel = ref.read(reportViewModelProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: ReportRange.values.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppChip(
                    label: _rangeLabel(r),
                    selected: viewModel.range == r,
                    onTap: () async {
                      if (r != ReportRange.custom) {
                        await viewModel.changeRange(r);
                        return;
                      }
                      final now = DateTime.now();
                      final selected = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: now,
                        initialDateRange:
                            viewModel.customRange ??
                            DateTimeRange(
                              start: now.subtract(const Duration(days: 30)),
                              end: now,
                            ),
                      );
                      if (selected != null) {
                        await viewModel.changeCustomRange(selected);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.when(
              loading: () => const AppLoadingState(),
              error: (message) =>
                  AppErrorState(message: message, onRetry: viewModel.load),
              empty: () => const AppEmptyState(
                title: 'Sin reportes',
                message:
                    'Todavía no hay suficientes movimientos para generar reportes.',
              ),
              success: (report) => ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Ingresos',
                          value: report.totalIncome,
                          color: colors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Gastos',
                          value: report.totalExpense,
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Balance',
                          value: report.balance,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(title: 'Distribución por categoría'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 46,
                                sections: report.distribution.map((d) {
                                  return PieChartSectionData(
                                    value: d.amount,
                                    color: d.category.color,
                                    radius: 26,
                                    showTitle: false,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: report.distribution.take(5).map((d) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: d.category.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          d.category.name,
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(title: 'Comparación mensual'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: report.trend.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value.income,
                                  color: colors.primary,
                                  width: 8,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                BarChartRodData(
                                  toY: e.value.expense,
                                  color: colors.textMuted,
                                  width: 8,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(title: 'Tendencia histórica'),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: report.trend
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.expense,
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: colors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: colors.primary.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AppSectionHeader(title: 'Insights'),
                  const SizedBox(height: AppSpacing.sm),
                  ...report.insights.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        elevation: AppCardElevation.elevated,
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: colors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                i,
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
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

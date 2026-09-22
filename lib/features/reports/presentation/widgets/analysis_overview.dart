import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/report_entity.dart';

class AnalysisSummaryCards extends StatelessWidget {
  const AnalysisSummaryCards({super.key, required this.report, this.previous});

  final ReportEntity report;
  final ReportEntity? previous;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Ingresos',
            value: report.totalIncome,
            previous: previous?.totalIncome,
            valueColor: colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Gastos',
            value: report.totalExpense,
            previous: previous?.totalExpense,
            valueColor: colors.error,
            lowerIsBetter: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Balance',
            value: report.balance,
            previous: previous?.balance,
            valueColor: report.balance >= 0 ? colors.primary : colors.error,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.previous,
    required this.valueColor,
    this.lowerIsBetter = false,
  });

  final String label;
  final double value;
  final double? previous;
  final Color valueColor;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final change = previous != null && previous != 0
        ? (value - previous!) / previous!.abs() * 100
        : null;
    final improved =
        change == null || (lowerIsBetter ? change <= 0 : change >= 0);
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatCompact(value),
              style: TextStyle(
                color: valueColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          if (change != null)
            Row(
              children: [
                Icon(
                  change >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 15,
                  color: improved ? colors.primary : colors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change >= 0 ? '+' : ''}${change.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: improved ? colors.primary : colors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          Text(
            change == null ? 'Sin comparación' : 'vs. período anterior',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textMuted, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class AnalysisBalanceCard extends StatelessWidget {
  const AnalysisBalanceCard({super.key, required this.trend, this.onDetails});

  final List<MonthlyTrendPoint> trend;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = [...trend]..sort((a, b) => a.month.compareTo(b.month));
    return _AnalysisPanel(
      title: 'Evolución del balance',
      subtitle: 'Ingresos, gastos y balance por mes',
      actionLabel: 'Ver detalle',
      onAction: onDetails,
      child: points.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'Aún no hay datos para mostrar.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _BalanceChartPainter(
                      points: points,
                      incomeColor: const Color(0xFF70D9A1),
                      expenseColor: const Color(0xFFF36B83),
                      balanceColor: colors.primary,
                      gridColor: colors.border,
                      labelColor: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _LegendDot('Ingresos', Color(0xFF70D9A1)),
                    _LegendDot('Gastos', Color(0xFFF36B83)),
                    _LegendDot('Balance', Color(0xFF008A59)),
                  ],
                ),
              ],
            ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  const _BalanceChartPainter({
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.balanceColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<MonthlyTrendPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final Color balanceColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(35, 8, size.width - 43, size.height - 38);
    final all = points.expand(
      (point) => [point.income, point.expense, point.income - point.expense],
    );
    final maxValue = math.max(1.0, all.reduce(math.max)) * 1.14;
    final minValue = math.min(0.0, all.reduce(math.min));
    final span = maxValue - minValue;
    double y(double value) =>
        chart.bottom - (value - minValue) / span * chart.height;
    final baseline = y(0);
    for (final fraction in [0.0, .5, 1.0]) {
      final value = minValue + span * fraction;
      final lineY = y(value);
      canvas.drawLine(
        Offset(chart.left, lineY),
        Offset(chart.right, lineY),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
      _drawLabel(
        canvas,
        _axisLabel(value),
        Offset(0, lineY - 7),
        labelColor,
        10,
      );
    }

    final step = chart.width / points.length;
    final barWidth = math.min(11.0, step * .15);
    final line = Path();
    final linePoints = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final centerX = chart.left + step * (index + .5);
      _bar(
        canvas,
        centerX - barWidth - 2,
        y(point.income),
        baseline,
        barWidth,
        incomeColor,
      );
      _bar(
        canvas,
        centerX + 2,
        y(point.expense),
        baseline,
        barWidth,
        expenseColor,
      );
      linePoints.add(Offset(centerX, y(point.income - point.expense)));
      final month = _shortMonth(point.month);
      _drawLabel(
        canvas,
        month,
        Offset(centerX, chart.bottom + 8),
        labelColor,
        10,
        centered: true,
      );
    }
    if (linePoints.isEmpty) return;
    line.moveTo(linePoints.first.dx, linePoints.first.dy);
    for (var i = 1; i < linePoints.length; i++) {
      final previous = linePoints[i - 1];
      final next = linePoints[i];
      final midpoint = (previous.dx + next.dx) / 2;
      line.cubicTo(midpoint, previous.dy, midpoint, next.dy, next.dx, next.dy);
    }
    final fill = Path.from(line)
      ..lineTo(linePoints.last.dx, baseline)
      ..lineTo(linePoints.first.dx, baseline)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            balanceColor.withValues(alpha: .17),
            balanceColor.withValues(alpha: 0),
          ],
        ).createShader(chart),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = balanceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (final point in linePoints) {
      canvas.drawCircle(point, 3.2, Paint()..color = balanceColor);
    }
  }

  void _bar(
    Canvas canvas,
    double x,
    double top,
    double baseline,
    double width,
    Color color,
  ) {
    final rect = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        x,
        math.min(top, baseline),
        x + width,
        math.max(top, baseline),
      ),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    canvas.drawRRect(rect, Paint()..color = color);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
    double fontSize, {
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centered ? position.translate(-painter.width / 2, 0) : position,
    );
  }

  String _axisLabel(double value) {
    if (value.abs() < 1) return '0';
    return CurrencyFormatter.formatCompact(value).replaceFirst('Gs. ', '');
  }

  String _shortMonth(DateTime date) {
    const names = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return names[date.month - 1];
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.balanceColor != balanceColor;
}

class AnalysisCategoryCard extends StatelessWidget {
  const AnalysisCategoryCard({
    super.key,
    required this.distribution,
    required this.onDetails,
  });

  final List<CategoryDistribution> distribution;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sorted = distribution.where((item) => item.amount > 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = sorted.fold<double>(0, (sum, item) => sum + item.amount);
    return _AnalysisPanel(
      title: 'Gastos por categoría',
      subtitle: 'Distribución de tus gastos en el período',
      actionLabel: 'Ver todas',
      onAction: onDetails,
      child: sorted.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'Aún no hay gastos en este período.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  width: 142,
                  height: 142,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 2,
                          centerSpaceRadius: 43,
                          sections: sorted.map((item) {
                            final percent = item.amount / total * 100;
                            return PieChartSectionData(
                              value: item.amount,
                              color: item.category.color,
                              radius: 25,
                              title: percent >= 11
                                  ? '${percent.toStringAsFixed(0)}%'
                                  : '',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatCompact(total),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'Total',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: sorted
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor: item.category.color,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CurrencyFormatter.formatCompact(item.amount),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(width: 4),
                Material(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(99),
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: colors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(radius: 5, backgroundColor: color),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
      ),
    ],
  );
}

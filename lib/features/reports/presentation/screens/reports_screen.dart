import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/report_entity.dart';
import '../viewmodels/report_viewmodel.dart';
import '../widgets/analysis_overview.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _section = 0;
  DateTime _selectedMonth = DateTime.now();
  bool _customMonth = false;
  ReportEntity? _previousReport;
  int _comparisonRequest = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPreviousReport);
  }

  Future<void> _loadPreviousReport() async {
    final request = ++_comparisonRequest;
    final viewModel = ref.read(reportViewModelProvider.notifier);
    final now = DateTime.now();
    DateTimeRange current;
    if (_customMonth || viewModel.range == ReportRange.month) {
      final month = _customMonth ? _selectedMonth : now;
      final lastDay = DateTime(month.year, month.month + 1, 0);
      current = DateTimeRange(
        start: DateTime(month.year, month.month),
        end: lastDay.isAfter(now) ? now : lastDay,
      );
    } else {
      current = switch (viewModel.range) {
        ReportRange.week => DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
        ReportRange.quarter => DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        ),
        ReportRange.year => DateTimeRange(start: DateTime(now.year), end: now),
        ReportRange.custom =>
          viewModel.customRange ??
              DateTimeRange(
                start: now.subtract(const Duration(days: 30)),
                end: now,
              ),
        ReportRange.month => DateTimeRange(
          start: DateTime(now.year, now.month),
          end: now,
        ),
      };
    }
    final previous = _customMonth || viewModel.range == ReportRange.month
        ? DateTimeRange(
            start: DateTime(current.start.year, current.start.month - 1),
            end: DateTime(current.start.year, current.start.month, 0),
          )
        : DateTimeRange(
            start: current.start.subtract(
              current.duration + const Duration(days: 1),
            ),
            end: current.start.subtract(const Duration(days: 1)),
          );
    if (mounted) setState(() => _previousReport = null);
    try {
      final report = await ref
          .read(reportRepositoryProvider)
          .getReport(ReportRange.custom, customRange: previous);
      if (mounted && request == _comparisonRequest) {
        setState(() => _previousReport = report);
      }
    } catch (_) {
      // El resumen sigue disponible cuando falla la comparación anterior.
    }
  }

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

  Future<void> _selectRange(ReportRange range) async {
    final viewModel = ref.read(reportViewModelProvider.notifier);
    if (range == ReportRange.custom) {
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
      if (selected == null || !mounted) return;
      setState(() => _customMonth = false);
      await viewModel.changeCustomRange(selected);
    } else {
      setState(() {
        _customMonth = false;
        if (range == ReportRange.month) _selectedMonth = DateTime.now();
      });
      await viewModel.changeRange(range);
    }
    if (mounted) _loadPreviousReport();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth.isAfter(now) ? now : _selectedMonth,
      firstDate: DateTime(2023),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedMonth = selected;
      _customMonth = true;
    });
    final lastDay = DateTime(selected.year, selected.month + 1, 0);
    await ref
        .read(reportViewModelProvider.notifier)
        .changeCustomRange(
          DateTimeRange(
            start: DateTime(selected.year, selected.month),
            end: lastDay.isAfter(now) ? now : lastDay,
          ),
        );
    if (mounted) _loadPreviousReport();
  }

  String _periodLabel(ReportViewModel viewModel) {
    if (_customMonth || viewModel.range == ReportRange.month) {
      final month = _customMonth ? _selectedMonth : DateTime.now();
      final text = DateFormatter.monthYear(month);
      return text[0].toUpperCase() + text.substring(1);
    }
    return switch (viewModel.range) {
      ReportRange.week => 'Últimos 7 días',
      ReportRange.quarter => 'Últimos 90 días',
      ReportRange.year => 'Año ${DateTime.now().year}',
      ReportRange.custom =>
        viewModel.customRange == null
            ? 'Período personalizado'
            : '${DateFormatter.short(viewModel.customRange!.start)} – ${DateFormatter.short(viewModel.customRange!.end)}',
      ReportRange.month => '',
    };
  }

  Widget _sectionTabs(AppSemanticColors colors) {
    const labels = ['Resumen', 'Categorías', 'Tendencias', 'Predicción'];
    return Container(
      height: 43,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _section = index),
                borderRadius: BorderRadius.circular(99),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _section == index
                        ? colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: _section == index
                            ? Colors.white
                            : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _periodControls(AppSemanticColors colors, ReportViewModel viewModel) {
    return Row(
      children: [
        PopupMenuButton<ReportRange>(
          onSelected: _selectRange,
          itemBuilder: (_) => [
            for (final range in ReportRange.values)
              PopupMenuItem(value: range, child: Text(_rangeLabel(range))),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: colors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _customMonth ? 'Mes' : _rangeLabel(viewModel.range),
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: (_customMonth || viewModel.range == ReportRange.month)
                ? _pickMonth
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _periodLabel(viewModel),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportViewModelProvider);
    final viewModel = ref.read(reportViewModelProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Análisis',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Conocé tus finanzas en detalle',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bar_chart_rounded, color: colors.primary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _sectionTabs(colors),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                13,
                AppSpacing.md,
                17,
              ),
              child: _periodControls(colors, viewModel),
            ),
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
                    if (_section == 0) ...[
                      AnalysisSummaryCards(
                        report: report,
                        previous: _previousReport,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnalysisBalanceCard(
                        trend: report.trend,
                        onDetails: () => setState(() => _section = 2),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnalysisCategoryCard(
                        distribution: report.expenseDistribution,
                        onDetails: () => setState(() => _section = 1),
                      ),
                    ],
                    if (_section == 1) ...[
                      const AppSectionHeader(
                        title: 'Distribución por categoría',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DistributionSection(
                        expenseDistribution: report.expenseDistribution,
                        incomeDistribution: report.incomeDistribution,
                      ),
                    ],
                    if (_section == 2) ...[
                      AnalysisBalanceCard(trend: report.trend),
                      const SizedBox(height: AppSpacing.lg),
                      const AppSectionHeader(title: 'Comparación mensual'),
                      const SizedBox(height: AppSpacing.sm),
                      if (report.trend.any(
                        (item) => item.income != 0 || item.expense != 0,
                      ))
                        _MonthlyComparisonCard(trend: report.trend)
                      else
                        const _ReportSectionEmpty(
                          icon: Icons.bar_chart_rounded,
                          title: 'Sin movimientos para comparar',
                          message:
                              'La comparación aparecerá cuando haya ingresos o gastos en el período seleccionado.',
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      const AppSectionHeader(title: 'Tendencia histórica'),
                      const SizedBox(height: AppSpacing.sm),
                      if (report.trend.any(
                        (item) => item.income != 0 || item.expense != 0,
                      ))
                        _HistoricalTrendCard(trend: report.trend)
                      else
                        const _ReportSectionEmpty(
                          icon: Icons.show_chart_rounded,
                          title: 'Sin tendencia disponible',
                          message:
                              'La evolución de tus gastos se mostrará cuando registres movimientos.',
                        ),
                    ],
                    if (_section == 3) ...[
                      const AppSectionHeader(title: 'Recomendaciones'),
                      const SizedBox(height: AppSpacing.sm),
                      if (report.insights.isEmpty)
                        const _ReportSectionEmpty(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Sin recomendaciones por ahora',
                          message:
                              'Cuando haya suficiente información, vas a recibir observaciones sobre tus finanzas.',
                        )
                      else
                        ...report.insights.map(
                          (insight) => Padding(
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
                                      insight,
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
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.predictions),
                        icon: const Icon(Icons.auto_graph_rounded),
                        label: const Text('Ver predicción completa'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DistributionKind { expense, income }

class _DistributionSection extends StatefulWidget {
  const _DistributionSection({
    required this.expenseDistribution,
    required this.incomeDistribution,
  });

  final List<CategoryDistribution> expenseDistribution;
  final List<CategoryDistribution> incomeDistribution;

  @override
  State<_DistributionSection> createState() => _DistributionSectionState();
}

class _DistributionSectionState extends State<_DistributionSection> {
  _DistributionKind _selected = _DistributionKind.expense;

  @override
  Widget build(BuildContext context) {
    final isIncome = _selected == _DistributionKind.income;
    final distribution = isIncome
        ? widget.incomeDistribution
        : widget.expenseDistribution;
    final hasData = distribution.any((item) => item.amount > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppChip(
              label: 'Gastos',
              selected: !isIncome,
              onTap: () =>
                  setState(() => _selected = _DistributionKind.expense),
            ),
            AppChip(
              label: 'Ingresos',
              selected: isIncome,
              onTap: () => setState(() => _selected = _DistributionKind.income),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (hasData)
          _CategoryDistributionCard(distribution: distribution, kind: _selected)
        else
          _ReportSectionEmpty(
            icon: Icons.pie_chart_outline_rounded,
            title: isIncome
                ? 'Sin ingresos por categoría'
                : 'Sin gastos por categoría',
            message: isIncome
                ? 'Cuando registres ingresos en este período, vas a ver cómo se distribuyen por categoría.'
                : 'Cuando registres gastos en este período, vas a ver cómo se distribuyen por categoría.',
          ),
      ],
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  const _CategoryDistributionCard({
    required this.distribution,
    required this.kind,
  });

  final List<CategoryDistribution> distribution;
  final _DistributionKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = distribution.where((item) => item.amount > 0).toList()
      ..sort((left, right) => right.amount.compareTo(left.amount));
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    final isIncome = kind == _DistributionKind.income;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isIncome
                ? 'Así se reparten tus ingresos'
                : 'Así se reparten tus gastos',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    sections: items.map((item) {
                      final percentage = total == 0
                          ? 0.0
                          : item.amount / total * 100;
                      return PieChartSectionData(
                        value: item.amount,
                        color: item.category.color,
                        radius: 34,
                        title: percentage >= 8
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
                      Text(
                        isIncome ? 'Total ingresos' : 'Total gastos',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.formatCompact(total),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...items.map((item) {
            final percentage = total == 0 ? 0.0 : item.amount / total * 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.category.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 86,
                    child: Text(
                      CurrencyFormatter.formatCompact(item.amount),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  const _MonthlyComparisonCard({required this.trend});

  final List<MonthlyTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = [...trend]
      ..sort((left, right) => left.month.compareTo(right.month));
    final highest = points.fold<double>(
      0,
      (value, point) => [
        value,
        point.income,
        point.expense,
      ].reduce((left, right) => left > right ? left : right),
    );
    final maxY = highest <= 0 ? 1.0 : highest * 1.18;
    final interval = maxY / 4;
    final labelStride = (points.length / 5).ceil().clamp(1, points.length);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos y gastos de cada mes',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChartLegend(
            items: [
              _LegendItem('Ingresos', colors.success),
              _LegendItem('Gastos', colors.error),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border.withValues(alpha: 0.7),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval,
                      getTitlesWidget: (value, _) => Text(
                        _axisAmount(value),
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelStride != 0 &&
                            index != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(points[index].month),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                      final color = rodIndex == 0
                          ? colors.success
                          : colors.error;
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.format(rod.toY)}',
                        TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: points.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.income,
                        color: colors.success,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: entry.value.expense,
                        color: colors.error,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Text(
            'Tocá una barra para consultar el monto exacto.',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HistoricalTrendCard extends StatelessWidget {
  const _HistoricalTrendCard({required this.trend});

  final List<MonthlyTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = [...trend]
      ..sort((left, right) => left.month.compareTo(right.month));
    if (points.length == 1) {
      final point = points.single;
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aún no hay meses suficientes para calcular una tendencia.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _fullMonthLabel(point.month),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _MonthlyValueRow(
              label: 'Ingresos',
              value: point.income,
              color: colors.success,
            ),
            const SizedBox(height: 8),
            _MonthlyValueRow(
              label: 'Gastos',
              value: point.expense,
              color: colors.error,
            ),
            const Divider(height: 24),
            _MonthlyValueRow(
              label: 'Balance',
              value: point.income - point.expense,
              color: point.income - point.expense >= 0
                  ? colors.success
                  : colors.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Al registrar movimientos en otros meses se mostrará su evolución.',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    final highest = points.fold<double>(
      0,
      (value, point) => [
        value,
        point.income,
        point.expense,
      ].reduce((left, right) => left > right ? left : right),
    );
    final maxY = highest <= 0 ? 1.0 : highest * 1.15;
    final interval = maxY / 4;
    final labelStride = (points.length / 5).ceil().clamp(1, points.length);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolución de ingresos y gastos',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChartLegend(
            items: [
              _LegendItem('Ingresos', colors.success),
              _LegendItem('Gastos', colors.error),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border.withValues(alpha: 0.7),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: interval,
                      getTitlesWidget: (value, _) => Text(
                        _axisAmount(value),
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelStride != 0 &&
                            index != points.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _monthLabel(points[index].month),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final income = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${income ? 'Ingresos' : 'Gastos'}\n'
                        '${CurrencyFormatter.format(spot.y)}',
                        TextStyle(
                          color: income ? colors.success : colors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _lineData(
                    points.map((point) => point.income).toList(),
                    colors.success,
                  ),
                  _lineData(
                    points.map((point) => point.expense).toList(),
                    colors.error,
                  ),
                ],
              ),
            ),
          ),
          Text(
            'Tocá un punto para consultar el monto exacto.',
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineData(List<double> values, Color color) =>
      LineChartBarData(
        spots: values
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
            .toList(),
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: FlDotData(show: values.length <= 6),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.08),
        ),
      );
}

class _MonthlyValueRow extends StatelessWidget {
  const _MonthlyValueRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
      ),
      Text(
        CurrencyFormatter.format(value),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: items
        .map(
          (item) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        )
        .toList(),
  );
}

class _LegendItem {
  const _LegendItem(this.label, this.color);

  final String label;
  final Color color;
}

String _axisAmount(double value) =>
    CurrencyFormatter.formatCompact(value).replaceFirst('Gs. ', '');

String _monthLabel(DateTime value) {
  const months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  return '${months[value.month - 1]} ${value.year.toString().substring(2)}';
}

String _fullMonthLabel(DateTime value) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[value.month - 1]} de ${value.year}';
}

class _ReportSectionEmpty extends StatelessWidget {
  const _ReportSectionEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

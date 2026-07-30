import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../categories/presentation/category_providers.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../domain/export_entity.dart';
import 'export_viewmodel.dart';
import '../../subscription/domain/subscription_entity.dart';
import '../../subscription/presentation/premium_gate.dart';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final MovementFilters initialFilters;
  const ExportScreen({
    super.key,
    this.initialFilters = const MovementFilters(),
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _format = ExportFormat.pdf;
  late DateTimeRange _range =
      widget.initialFilters.dateRange ??
      DateTimeRange(
        start: DateTime(DateTime.now().year, DateTime.now().month, 1),
        end: DateTime.now(),
      );
  late MovementFilters _filters = widget.initialFilters;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  String _buildFiltersSummary() {
    final parts = <String>[];
    if (_filters.type != null) {
      parts.add(
        _filters.type!.name == 'income' ? 'Solo ingresos' : 'Solo gastos',
      );
    }
    if (_filters.categoryId != null) {
      final categories = ref
          .read(categoryListViewModelProvider)
          .when(
            loading: () => null,
            error: (_) => null,
            empty: () => null,
            success: (c) => c,
          );
      final category = categories
          ?.where((c) => c.id == _filters.categoryId)
          .toList();
      if (category != null && category.isNotEmpty) {
        parts.add('Categoría: ${category.first.name}');
      }
    }
    if (_filters.accountId != null) {
      final accounts = ref
          .read(accountListViewModelProvider)
          .when(
            loading: () => null,
            error: (_) => null,
            empty: () => null,
            success: (a) => a,
          );
      final account = accounts
          ?.where((a) => a.id == _filters.accountId)
          .toList();
      if (account != null && account.isNotEmpty) {
        parts.add('Cuenta: ${account.first.name}');
      }
    }
    if (_filters.ocrFilter != OcrFilter.any) {
      parts.add(
        _filters.ocrFilter == OcrFilter.withOcr
            ? 'Solo con OCR'
            : 'Solo sin OCR',
      );
    }
    return parts.isEmpty ? 'Sin filtros adicionales' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(exportViewModelProvider);
    final history = ref.watch(exportHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Extracto de movimientos')),
      body: PremiumGate(
        capability: PremiumCapability.exports,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Formato',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FormatOption(
                    label: 'PDF',
                    selected: _format == ExportFormat.pdf,
                    onTap: () => setState(() => _format = ExportFormat.pdf),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormatOption(
                    label: 'Excel',
                    selected: _format == ExportFormat.excel,
                    onTap: () => setState(() => _format = ExportFormat.excel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Rango de fechas',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickRange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormatter.short(_range.start)} - ${DateFormatter.short(_range.end)}',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            if (_filters.hasAdvancedFilters || _filters.type != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se respetarán los filtros activos de Movimientos: ${_buildFiltersSummary()}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _filters = const MovementFilters()),
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            state.when(
              empty: () => AppButton(
                label: 'Generar extracto',
                onPressed: () => ref
                    .read(exportViewModelProvider.notifier)
                    .export(
                      format: _format,
                      range: _range,
                      filters: _filters,
                      filtersSummary: _buildFiltersSummary(),
                    ),
              ),
              loading: () => const AppButton(
                label: 'Generando...',
                onPressed: null,
                isLoading: true,
              ),
              error: (message) => Column(
                children: [
                  Text(
                    message,
                    style: TextStyle(color: colors.error, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reintentar',
                    onPressed: () =>
                        ref.read(exportViewModelProvider.notifier).reset(),
                  ),
                ],
              ),
              success: (record) => _StatementSummaryCard(record: record),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Historial de extractos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            history.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (records) => records.isEmpty
                  ? Text(
                      'Todavía no generaste ningún extracto.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  : Column(
                      children: records.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            child: Row(
                              children: [
                                Icon(
                                  r.format == ExportFormat.pdf
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.table_chart_outlined,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.range,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.medium(r.date),
                                        style: TextStyle(
                                          color: colors.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${r.movementCount} mov.',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementSummaryCard extends StatelessWidget {
  final ExportRecord record;
  const _StatementSummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      elevation: AppCardElevation.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: colors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extracto en ${record.format == ExportFormat.pdf ? 'PDF' : 'Excel'} listo para ${record.range}.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _row(
            context,
            'Ingresos',
            CurrencyFormatter.format(record.totalIncome),
            colors.success,
          ),
          const SizedBox(height: 6),
          _row(
            context,
            'Egresos',
            CurrencyFormatter.format(record.totalExpense),
            colors.textPrimary,
          ),
          const SizedBox(height: 6),
          _row(
            context,
            'Transferencias',
            CurrencyFormatter.format(record.totalTransferred),
            colors.info,
          ),
          const Divider(height: AppSpacing.lg),
          _row(
            context,
            'Balance neto',
            CurrencyFormatter.formatSigned(record.netBalance),
            record.netBalance >= 0 ? colors.success : colors.error,
          ),
          const SizedBox(height: 6),
          _row(
            context,
            'Movimientos incluidos',
            '${record.movementCount}',
            colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            record.filtersSummary,
            style: TextStyle(color: colors.textMuted, fontSize: 11.5),
          ),
          if (record.artifactPath != null) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Abrir o compartir extracto',
              icon: Icons.share_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  files: [XFile(record.artifactPath!)],
                  subject: 'Extracto financiero ${record.range}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FormatOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.16)
              : colors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? colors.primary : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

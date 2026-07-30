import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/budget_entity.dart';
import 'budget_viewmodel.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(
          message: message,
          onRetry: ref.read(budgetViewModelProvider.notifier).load,
        ),
        empty: () => AppEmptyState(
          title: 'Sin presupuesto definido',
          message: 'Definí un presupuesto para empezar a hacer seguimiento.',
          actionLabel: 'Crear presupuesto',
          onAction: () => _openEditor(context),
        ),
        success: (overview) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            _BudgetCard(
              budget: overview.overall,
              highlighted: true,
              isOverall: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppSectionHeader(title: 'Presupuestos personalizados'),
            const SizedBox(height: AppSpacing.sm),
            if (overview.categoryBudgets.isEmpty)
              Text(
                'Todavía no creaste presupuestos personalizados.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ...overview.categoryBudgets.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _BudgetCard(budget: b),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openEditor(BuildContext context, {BudgetEntity? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetEditorSheet(budget: budget),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetEntity budget;
  final bool highlighted;
  final bool isOverall;
  const _BudgetCard({
    required this.budget,
    this.highlighted = false,
    this.isOverall = false,
  });

  String _statusLabel(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.healthy:
        return 'Saludable';
      case BudgetStatus.atRisk:
        return 'En riesgo';
      case BudgetStatus.exceeded:
        return 'Excedido';
    }
  }

  AppBadgeTone _statusTone(BudgetStatus s) {
    switch (s) {
      case BudgetStatus.healthy:
        return AppBadgeTone.success;
      case BudgetStatus.atRisk:
        return AppBadgeTone.warning;
      case BudgetStatus.exceeded:
        return AppBadgeTone.error;
    }
  }

  Color _progressColor(BuildContext context, BudgetStatus s) {
    final colors = context.colors;
    switch (s) {
      case BudgetStatus.healthy:
        return colors.primary;
      case BudgetStatus.atRisk:
        return colors.warning;
      case BudgetStatus.exceeded:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final available = budget.remaining;

    return AppCard(
      elevation: highlighted
          ? AppCardElevation.elevated
          : AppCardElevation.surface,
      onTap: () =>
          BudgetsScreen._openEditor(context, budget: isOverall ? null : budget),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    if (budget.categories.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        budget.categories.map((c) => c.name).join(', '),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppBadge(
                    label: _statusLabel(budget.status),
                    tone: _statusTone(budget.status),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    budget.period.label,
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: budget.progress.clamp(0, 1),
              minHeight: 8,
              backgroundColor: colors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(
                _progressColor(context, budget.status),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatCompact(budget.spent)} de ${CurrencyFormatter.formatCompact(budget.amount)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              Text(
                available >= 0
                    ? 'Disponible ${CurrencyFormatter.formatCompact(available)}'
                    : 'Excedido ${CurrencyFormatter.formatCompact(-available)}',
                style: TextStyle(
                  color: available >= 0 ? colors.textMuted : colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetEditorSheet extends ConsumerStatefulWidget {
  final BudgetEntity? budget;
  const _BudgetEditorSheet({this.budget});

  @override
  ConsumerState<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<_BudgetEditorSheet> {
  late final _name = TextEditingController(text: widget.budget?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.budget?.amount.toStringAsFixed(0) ?? '',
  );
  late BudgetPeriod _period = widget.budget?.period ?? BudgetPeriod.monthly;
  late final List<CategoryEntity> _categories = List.of(
    widget.budget?.categories ?? [],
  );
  String? _errorMessage;

  bool get isEditing => widget.budget != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(categoryListViewModelProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.error,
                      ),
                      onPressed: () async {
                        await ref
                            .read(budgetViewModelProvider.notifier)
                            .deleteBudget(widget.budget!.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nombre',
                controller: _name,
                hint: 'Ej. Ocio y entretenimiento',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Monto presupuestado (Gs.)',
                controller: _amount,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Período de vigencia',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BudgetPeriod.values.map((p) {
                  final selected = p == _period;
                  return GestureDetector(
                    onTap: () => setState(() => _period = p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary
                            : colors.surfaceElevated,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: selected ? Colors.white : colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Categorías incluidas',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              categoriesState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_) => const SizedBox.shrink(),
                empty: () => const SizedBox.shrink(),
                success: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final selected = _categories.any((s) => s.id == c.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (selected) {
                          _categories.removeWhere((s) => s.id == c.id);
                        } else {
                          _categories.add(c);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? c.color : colors.surfaceElevated,
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              c.icon,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.name,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontSize: 13,
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
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: isEditing ? 'Guardar cambios' : 'Crear presupuesto',
                onPressed: _name.text.trim().isEmpty
                    ? null
                    : () async {
                        final viewModel = ref.read(
                          budgetViewModelProvider.notifier,
                        );
                        final amount = double.tryParse(_amount.text) ?? 0;
                        if (amount <= 0) {
                          setState(
                            () => _errorMessage = 'Ingresá un monto válido.',
                          );
                          return;
                        }
                        if (_categories.isEmpty) {
                          setState(
                            () => _errorMessage =
                                'Seleccioná al menos una categoría.',
                          );
                          return;
                        }
                        final entity = BudgetEntity(
                          id: widget.budget?.id ?? '',
                          name: _name.text.trim(),
                          amount: amount,
                          spent: widget.budget?.spent ?? 0,
                          period: _period,
                          categories: _categories,
                        );
                        final error = isEditing
                            ? await viewModel.updateBudget(entity)
                            : await viewModel.createBudget(entity);
                        if (error != null) {
                          setState(() => _errorMessage = error);
                          return;
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

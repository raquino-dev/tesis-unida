import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_searchable_selector.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/presentation/category_providers.dart';
import '../../movements/domain/movement_entity.dart';
import '../domain/recurring_movement_entity.dart';
import 'recurring_movement_providers.dart';

class RecurringMovementListScreen extends ConsumerWidget {
  const RecurringMovementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringMovementListViewModelProvider);
    final viewModel = ref.read(recurringMovementListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos recurrentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) =>
            AppErrorState(message: message, onRetry: viewModel.load),
        empty: () => AppEmptyState(
          icon: Icons.autorenew_rounded,
          title: 'Sin movimientos recurrentes',
          message: 'Programá ingresos o gastos que se repitan automáticamente.',
          actionLabel: 'Crear recurrencia',
          onAction: () => _openEditor(context),
        ),
        success: (items) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) =>
              _RecurringTile(recurring: items[index]),
        ),
      ),
    );
  }

  static void _openEditor(
    BuildContext context, {
    RecurringMovementEntity? recurring,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringEditorSheet(recurring: recurring),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  final RecurringMovementEntity recurring;
  const _RecurringTile({required this.recurring});

  AppBadgeTone _statusTone(RecurringStatus s) {
    switch (s) {
      case RecurringStatus.active:
        return AppBadgeTone.success;
      case RecurringStatus.paused:
        return AppBadgeTone.warning;
      case RecurringStatus.finished:
        return AppBadgeTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isIncome = recurring.type == MovementType.income;
    return AppCard(
      onTap: () => RecurringMovementListScreen._openEditor(
        context,
        recurring: recurring,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  recurring.description,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              AppBadge(
                label: recurring.status.label,
                tone: _statusTone(recurring.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${recurring.categories.map((c) => c.name).join(', ')} · ${recurring.account.name}',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(recurring.amount)}',
                style: TextStyle(
                  color: isIncome ? colors.success : colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                recurring.frequency.label,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            recurring.status == RecurringStatus.finished
                ? 'Finalizó el ${DateFormatter.short(recurring.endDate ?? recurring.nextExecutionDate)}'
                : 'Próxima ejecución: ${DateFormatter.short(recurring.nextExecutionDate)}',
            style: TextStyle(color: colors.textMuted, fontSize: 11.5),
          ),
          if (recurring.status != RecurringStatus.finished) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: recurring.status == RecurringStatus.active
                        ? 'Pausar'
                        : 'Reanudar',
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => ref
                        .read(recurringMovementListViewModelProvider.notifier)
                        .setStatus(
                          recurring,
                          recurring.status == RecurringStatus.active
                              ? RecurringStatus.paused
                              : RecurringStatus.active,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Finalizar',
                    variant: AppButtonVariant.ghost,
                    fullWidth: true,
                    onPressed: () => ref
                        .read(recurringMovementListViewModelProvider.notifier)
                        .setStatus(recurring, RecurringStatus.finished),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringEditorSheet extends ConsumerStatefulWidget {
  final RecurringMovementEntity? recurring;
  const _RecurringEditorSheet({this.recurring});

  @override
  ConsumerState<_RecurringEditorSheet> createState() =>
      _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends ConsumerState<_RecurringEditorSheet> {
  late MovementType _type = widget.recurring?.type ?? MovementType.expense;
  late final _amount = TextEditingController(
    text: widget.recurring?.amount.toStringAsFixed(0) ?? '',
  );
  late final _description = TextEditingController(
    text: widget.recurring?.description ?? '',
  );
  late DateTime _startDate = widget.recurring?.startDate ?? DateTime.now();
  DateTime? _endDate;
  bool _indefinite = true;
  late RecurrenceFrequency _frequency =
      widget.recurring?.frequency ?? RecurrenceFrequency.monthly;
  late final _occurrences = TextEditingController(
    text: widget.recurring?.totalOccurrences?.toString() ?? '',
  );
  List<CategoryEntity> _categories = [];
  AccountEntity? _account;
  String? _errorMessage;

  bool get isEditing => widget.recurring != null;

  @override
  void initState() {
    super.initState();
    if (widget.recurring != null) {
      _categories = List.of(widget.recurring!.categories);
      _account = widget.recurring!.account;
      _endDate = widget.recurring!.endDate;
      _indefinite = widget.recurring!.endDate == null;
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(categoryListViewModelProvider);
    final accountsState = ref.watch(accountListViewModelProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    isEditing ? 'Editar recurrencia' : 'Nueva recurrencia',
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
                            .read(
                              recurringMovementListViewModelProvider.notifier,
                            )
                            .delete(widget.recurring!.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppChip(
                      label: 'Gasto',
                      selected: _type == MovementType.expense,
                      onTap: () => setState(() => _type = MovementType.expense),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppChip(
                      label: 'Ingreso',
                      selected: _type == MovementType.income,
                      onTap: () => setState(() => _type = MovementType.income),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Monto (Gs.)',
                controller: _amount,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Descripción',
                controller: _description,
                hint: 'Ej. Suscripción streaming',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Categorías',
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
                success: (categories) =>
                    AppSearchableMultiSelector<CategoryEntity>(
                      items: categories,
                      idOf: (item) => item.id,
                      labelOf: (item) => item.name,
                      leadingOf: (item) => Icon(item.icon, color: item.color),
                      values: _categories,
                      hint: 'Buscar y seleccionar categorías',
                      searchHint: 'Buscar categorías',
                      onChanged: (values) =>
                          setState(() => _categories = values),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cuenta',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              accountsState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_) => const SizedBox.shrink(),
                empty: () => const SizedBox.shrink(),
                success: (accounts) {
                  _account ??= accounts.isNotEmpty ? accounts.first : null;
                  return AppSearchableSingleSelector<AccountEntity>(
                    items: accounts,
                    idOf: (item) => item.id,
                    labelOf: (item) => item.name,
                    leadingOf: (item) => Icon(item.icon, color: colors.primary),
                    value: _account,
                    hint: 'Seleccionar cuenta',
                    searchHint: 'Buscar cuentas',
                    onChanged: (value) => setState(() => _account = value),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Frecuencia',
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
                children: RecurrenceFrequency.values.map((f) {
                  final selected = f == _frequency;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = f),
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
                        f.label,
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
                'Fecha de inicio',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: _pickStartDate,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormatter.short(_startDate),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Switch(
                    value: !_indefinite,
                    onChanged: (v) => setState(() => _indefinite = !v),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tiene fecha de término',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_indefinite) ...[
                const SizedBox(height: 8),
                AppCard(
                  onTap: _pickEndDate,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _endDate == null
                            ? 'Elegir fecha de término'
                            : DateFormatter.short(_endDate!),
                        style: TextStyle(color: colors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Cantidad de repeticiones (opcional)',
                controller: _occurrences,
                keyboardType: TextInputType.number,
                hint: 'Indefinida si se deja vacío',
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
                label: isEditing ? 'Guardar cambios' : 'Crear recurrencia',
                onPressed: _account == null
                    ? null
                    : () async {
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
                        if (!_indefinite && _endDate == null) {
                          setState(
                            () => _errorMessage =
                                'Elegí una fecha de término o marcá la recurrencia como indefinida.',
                          );
                          return;
                        }
                        final entity = RecurringMovementEntity(
                          id: widget.recurring?.id ?? '',
                          type: _type,
                          amount: amount,
                          categories: _categories,
                          account: _account!,
                          description: _description.text.trim().isEmpty
                              ? _categories.first.name
                              : _description.text.trim(),
                          startDate: _startDate,
                          endDate: _indefinite ? null : _endDate,
                          frequency: _frequency,
                          totalOccurrences: int.tryParse(_occurrences.text),
                          nextExecutionDate:
                              widget.recurring?.nextExecutionDate ?? _startDate,
                          status:
                              widget.recurring?.status ??
                              RecurringStatus.active,
                        );
                        final viewModel = ref.read(
                          recurringMovementListViewModelProvider.notifier,
                        );
                        final error = isEditing
                            ? await viewModel.update(entity)
                            : await viewModel.create(entity);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_searchable_selector.dart';
import '../domain/family_entity.dart';
import 'family_providers.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../security/presentation/widgets/otp_verification_dialog.dart';
import '../../categories/domain/category_entity.dart';

class FamilyFinanceScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const FamilyFinanceScreen({super.key, this.initialIndex = 0});
  @override
  ConsumerState<FamilyFinanceScreen> createState() =>
      _FamilyFinanceScreenState();
}

class _FamilyFinanceScreenState extends ConsumerState<FamilyFinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialIndex,
  );
  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Finanzas familiares'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Caja'),
          Tab(text: 'Presupuestos'),
          Tab(text: 'Reporte'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: const [_TreasuryTab(), _FamilyBudgetsTab(), _FamilyReportTab()],
    ),
  );
}

class _TreasuryTab extends ConsumerWidget {
  const _TreasuryTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(treasuryOperationsProvider);
    final groupState = ref.watch(familyViewModelProvider);
    final currentMember = groupState.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (group) => group.members.firstWhere(
        (member) => member.id == (group.currentMemberId ?? 'you'),
        orElse: () => group.members.first,
      ),
    );
    final canManage = currentMember?.role.canManageGroup ?? false;
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Creá un grupo familiar para utilizar la caja.\n$error',
          textAlign: TextAlign.center,
        ),
      ),
      data: (operations) {
        final balance = operations.fold<double>(
          0,
          (sum, op) =>
              sum +
              (op.type == TreasuryOperationType.contribution
                  ? op.amount
                  : -op.amount),
        );
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              elevation: AppCardElevation.elevated,
              child: Column(
                children: [
                  Text(
                    'Saldo de la caja',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Aportar',
                          onPressed: () => _openOperation(
                            context,
                            TreasuryOperationType.contribution,
                            currentMember,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Retirar',
                          variant: AppButtonVariant.secondary,
                          onPressed: canManage
                              ? () => _openOperation(
                                  context,
                                  TreasuryOperationType.withdrawal,
                                  currentMember,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!AppEnvironment.useApi)
                    AppButton(
                      label: 'Registrar gasto desde la caja',
                      variant: AppButtonVariant.ghost,
                      onPressed: canManage
                          ? () => _openOperation(
                              context,
                              TreasuryOperationType.sharedExpense,
                              currentMember,
                            )
                          : null,
                    ),
                  if (!canManage)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Sólo administradores pueden retirar o utilizar fondos.',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Trazabilidad de operaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (operations.isEmpty)
              const Text('Todavía no hay operaciones.')
            else
              ...operations.map(
                (op) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        op.type == TreasuryOperationType.contribution
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                      ),
                      title: Text(op.description),
                      subtitle: Text(op.memberName),
                      trailing: Text(
                        '${op.type == TreasuryOperationType.contribution ? '+' : '-'}${CurrencyFormatter.format(op.amount)}',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openOperation(
    BuildContext context,
    TreasuryOperationType type,
    FamilyMemberEntity? member,
  ) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TreasuryOperationSheet(type: type, member: member),
  );
}

class _TreasuryOperationSheet extends ConsumerStatefulWidget {
  final TreasuryOperationType type;
  final FamilyMemberEntity? member;
  const _TreasuryOperationSheet({required this.type, required this.member});
  @override
  ConsumerState<_TreasuryOperationSheet> createState() =>
      _TreasuryOperationSheetState();
}

class _TreasuryOperationSheetState
    extends ConsumerState<_TreasuryOperationSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  AccountEntity? _account;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountListViewModelProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.type == TreasuryOperationType.contribution
                ? 'Nuevo aporte'
                : widget.type == TreasuryOperationType.withdrawal
                ? 'Retiro de caja'
                : 'Gasto compartido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Monto',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Concepto', controller: _description),
          if (widget.type != TreasuryOperationType.sharedExpense) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.type == TreasuryOperationType.contribution
                    ? 'Cuenta de origen'
                    : 'Cuenta de destino',
              ),
            ),
            const SizedBox(height: 8),
            accountsState.when(
              loading: () => const LinearProgressIndicator(),
              error: (_) => const Text('No pudimos cargar tus cuentas.'),
              empty: () =>
                  const Text('Creá una cuenta antes de operar con la caja.'),
              success: (accounts) {
                final active = accounts
                    .where((account) => account.isActive)
                    .toList();
                return AppSearchableSingleSelector<AccountEntity>(
                  items: active,
                  idOf: (item) => item.id,
                  labelOf: (item) => item.name,
                  leadingOf: (item) => Icon(
                    item.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  value: _account,
                  hint: 'Seleccionar cuenta',
                  searchHint: 'Buscar cuentas',
                  onChanged: (value) => setState(() => _account = value),
                );
              },
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Confirmar',
            onPressed: () async {
              try {
                if (widget.type != TreasuryOperationType.sharedExpense &&
                    _account == null) {
                  setState(() => _error = 'Seleccioná una cuenta.');
                  return;
                }
                String? verificationId;
                if (widget.type != TreasuryOperationType.contribution) {
                  final verifiedId = await requestOtpVerification(
                    context,
                    ref,
                    reason: widget.type == TreasuryOperationType.withdrawal
                        ? 'Retiro de caja familiar'
                        : 'Gasto desde caja familiar',
                  );
                  if (verifiedId == null || !mounted) return;
                  verificationId = verifiedId;
                }
                await ref
                    .read(familyRepositoryProvider)
                    .addTreasuryOperation(
                      TreasuryOperationEntity(
                        id: '',
                        type: widget.type,
                        amount: double.tryParse(_amount.text) ?? 0,
                        description: _description.text.trim().isEmpty
                            ? 'Operación de caja'
                            : _description.text.trim(),
                        memberName: widget.member?.name ?? 'Integrante',
                        actorRole: widget.member?.role ?? FamilyRole.member,
                        date: DateTime.now(),
                        accountId: _account?.id,
                        accountName: _account?.name,
                        otpVerificationId: verificationId,
                      ),
                    );
                ref.invalidate(treasuryOperationsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                setState(() => _error = error.toString());
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FamilyBudgetsTab extends ConsumerWidget {
  const _FamilyBudgetsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyBudgetsProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (budgets) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppButton(
            label: 'Crear presupuesto familiar',
            icon: Icons.add,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _FamilyBudgetSheet(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...budgets.map(
            (budget) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: budget.progress.clamp(0, 1)),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} de ${CurrencyFormatter.format(budget.amount)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyBudgetSheet extends ConsumerStatefulWidget {
  const _FamilyBudgetSheet();
  @override
  ConsumerState<_FamilyBudgetSheet> createState() => _FamilyBudgetSheetState();
}

class _FamilyBudgetSheetState extends ConsumerState<_FamilyBudgetSheet> {
  CategoryEntity? _category;
  final _amount = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(familyCategoriesProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Presupuesto familiar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Categoría'),
          ),
          const SizedBox(height: 8),
          categoriesState.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('No pudimos cargar las categorías.'),
            data: (categories) => categories.isEmpty
                ? const Text('No hay categorías disponibles.')
                : AppSearchableSingleSelector<CategoryEntity>(
                    items: categories,
                    idOf: (item) => item.id,
                    labelOf: (item) => item.name,
                    leadingOf: (item) => Icon(item.icon, color: item.color),
                    value: _category,
                    hint: 'Seleccionar categoría',
                    searchHint: 'Buscar categorías',
                    onChanged: (value) => setState(() => _category = value),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Monto',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Guardar',
            onPressed: _category == null
                ? null
                : () async {
                    await ref
                        .read(familyRepositoryProvider)
                        .saveFamilyBudget(
                          FamilyBudgetEntity(
                            id: '',
                            categoryName: _category!.name,
                            amount: double.tryParse(_amount.text) ?? 0,
                            spent: 0,
                            categoryId: _category!.id,
                          ),
                        );
                    ref.invalidate(familyBudgetsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}

enum _FamilyReportRange { week, month, custom }

class _FamilyReportTab extends ConsumerStatefulWidget {
  const _FamilyReportTab();
  @override
  ConsumerState<_FamilyReportTab> createState() => _FamilyReportTabState();
}

class _FamilyReportTabState extends ConsumerState<_FamilyReportTab> {
  _FamilyReportRange _range = _FamilyReportRange.month;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    final movements = ref.watch(familyMovementListViewModelProvider);
    final budgets = ref.watch(familyBudgetsProvider);
    return movements.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (message) => Center(child: Text(message)),
      empty: () => _report(context, const [], budgets),
      success: (items) => _report(context, items, budgets),
    );
  }

  Widget _report(
    BuildContext context,
    List<FamilyMovementEntity> movements,
    AsyncValue<List<FamilyBudgetEntity>> budgets,
  ) {
    final now = DateTime.now();
    final start = _range == _FamilyReportRange.week
        ? now.subtract(const Duration(days: 7))
        : _range == _FamilyReportRange.month
        ? DateTime(now.year, now.month, 1)
        : _customRange?.start;
    final end = _range == _FamilyReportRange.custom ? _customRange?.end : now;
    final filtered = movements.where((movement) {
      if (start != null && movement.date.isBefore(start)) return false;
      if (end != null &&
          movement.date.isAfter(
            DateTime(end.year, end.month, end.day, 23, 59, 59),
          )) {
        return false;
      }
      return true;
    }).toList();
    final income = filtered
        .where((m) => m.type == FamilyMovementType.income)
        .fold<double>(0, (sum, m) => sum + m.amount);
    final expense = filtered
        .where((m) => m.type == FamilyMovementType.expense)
        .fold<double>(0, (sum, m) => sum + m.amount);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Dashboard familiar',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<_FamilyReportRange>(
          segments: const [
            ButtonSegment(
              value: _FamilyReportRange.week,
              label: Text('Semana'),
            ),
            ButtonSegment(value: _FamilyReportRange.month, label: Text('Mes')),
            ButtonSegment(
              value: _FamilyReportRange.custom,
              label: Text('Rango'),
            ),
          ],
          selected: {_range},
          onSelectionChanged: (selection) async {
            final value = selection.first;
            if (value == _FamilyReportRange.custom) {
              final selected = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: now,
                initialDateRange:
                    _customRange ??
                    DateTimeRange(
                      start: now.subtract(const Duration(days: 30)),
                      end: now,
                    ),
              );
              if (selected == null) return;
              setState(() {
                _range = value;
                _customRange = selected;
              });
              return;
            }
            setState(() => _range = value);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevation: AppCardElevation.elevated,
          child: Column(
            children: [
              _metric('Ingresos compartidos', income),
              _metric('Gastos compartidos', expense),
              const Divider(),
              _metric('Balance familiar', income - expense),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Comparación con presupuestos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        budgets.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (items) => Column(
            children: items
                .map(
                  (b) => ListTile(
                    title: Text(b.categoryName),
                    subtitle: LinearProgressIndicator(
                      value: b.progress.clamp(0, 1),
                    ),
                    trailing: Text('${(b.progress * 100).toStringAsFixed(0)}%'),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, double value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          CurrencyFormatter.format(value),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_searchable_selector.dart';
import '../domain/savings_goal_entity.dart';
import 'savings_goal_providers.dart';
import '../../family/presentation/family_providers.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../../core/services/pilot_local_store.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savingsGoalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            appErrorMessage(
              error,
              fallback: 'No pudimos cargar tus metas de ahorro.',
            ),
          ),
        ),
        data: (goals) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _section(
              context,
              ref,
              'Metas privadas',
              goals
                  .where((goal) => goal.scope == SavingsGoalScope.private)
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _section(
              context,
              ref,
              'Metas compartidas',
              goals
                  .where((goal) => goal.scope == SavingsGoalScope.family)
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<SavingsGoalEntity> goals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (goals.isEmpty)
          const Text('No hay metas en este ámbito.')
        else
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _openCreate(context, goal),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        if (goal.savedAmount <= 0)
                          IconButton(
                            tooltip: 'Eliminar meta',
                            onPressed: () => ref
                                .read(savingsGoalProvider.notifier)
                                .delete(goal.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                      ],
                    ),
                    LinearProgressIndicator(value: goal.progress),
                    const SizedBox(height: 8),
                    Text(
                      '${CurrencyFormatter.format(goal.savedAmount)} de ${CurrencyFormatter.format(goal.targetAmount)}',
                    ),
                    Text(
                      'Objetivo: ${DateFormatter.short(goal.targetDate)}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _openContribution(context, goal),
                        child: const Text('Registrar aporte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openCreate(BuildContext context, [SavingsGoalEntity? goal]) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _CreateGoalSheet(goal: goal),
      );
  void _openContribution(BuildContext context, SavingsGoalEntity goal) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _ContributionSheet(goal: goal),
      );
}

class _CreateGoalSheet extends ConsumerStatefulWidget {
  final SavingsGoalEntity? goal;
  const _CreateGoalSheet({this.goal});
  @override
  ConsumerState<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<_CreateGoalSheet> {
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target = TextEditingController(
    text: widget.goal?.targetAmount.toStringAsFixed(0) ?? '',
  );
  late SavingsGoalScope _scope = widget.goal?.scope ?? SavingsGoalScope.private;
  late DateTime _targetDate =
      widget.goal?.targetDate ?? DateTime.now().add(const Duration(days: 180));
  late String? _accountId = widget.goal?.accountId;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyViewModelProvider);
    final accountsState = ref.watch(accountListViewModelProvider);
    final familyGroup = familyState.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (group) => group,
    );
    final hasFamily = familyState.when(
      loading: () => false,
      error: (_) => false,
      empty: () => false,
      success: (_) => true,
    );
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
          Text('Nueva meta', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Nombre', controller: _name),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Monto objetivo',
            controller: _target,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<SavingsGoalScope>(
            segments: const [
              ButtonSegment(
                value: SavingsGoalScope.private,
                label: Text('Privada'),
              ),
              ButtonSegment(
                value: SavingsGoalScope.family,
                label: Text('Compartida'),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: widget.goal == null
                ? (value) => setState(() {
                    _scope = value.first;
                    _accountId = null;
                  })
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Cuenta de la meta'),
          ),
          const SizedBox(height: 8),
          accountsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (_) => const Text('No pudimos cargar tus cuentas.'),
            empty: () => const Text('No tenés cuentas disponibles.'),
            success: (personalAccounts) {
              final accounts = _scope == SavingsGoalScope.family
                  ? (familyGroup?.sharedAccounts ?? const <AccountEntity>[])
                  : personalAccounts;
              final active = accounts
                  .where((account) => account.isActive)
                  .toList();
              return AppSearchableSingleSelector<AccountEntity>(
                items: active,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                leadingOf: (item) =>
                    Icon(item.icon, color: context.colors.primary),
                value: active
                    .where((account) => account.id == _accountId)
                    .firstOrNull,
                hint: 'Seleccionar cuenta',
                searchHint: 'Buscar cuentas',
                enabled: widget.goal == null,
                onChanged: (value) => setState(() => _accountId = value.id),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _targetDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (selected != null) setState(() => _targetDate = selected);
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Fecha objetivo'),
              trailing: Text(DateFormatter.short(_targetDate)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: widget.goal == null ? 'Crear meta' : 'Guardar cambios',
            onPressed: () async {
              if (_name.text.trim().isEmpty ||
                  (double.tryParse(_target.text) ?? 0) <= 0 ||
                  _accountId == null) {
                setState(
                  () => _error = 'Completá nombre, monto y cuenta de la meta.',
                );
                return;
              }
              if (_scope == SavingsGoalScope.family && !hasFamily) {
                setState(
                  () => _error =
                      'Creá o aceptá un grupo familiar antes de crear una meta compartida.',
                );
                return;
              }
              final goal = SavingsGoalEntity(
                id: widget.goal?.id ?? '',
                name: _name.text.trim(),
                targetAmount: double.tryParse(_target.text) ?? 0,
                savedAmount: widget.goal?.savedAmount ?? 0,
                targetDate: _targetDate,
                scope: _scope,
                accountId: _accountId,
                accountName: widget.goal?.accountName,
                familyGroupId: _scope == SavingsGoalScope.family
                    ? familyGroup?.id
                    : null,
                version: widget.goal?.version ?? 1,
              );
              final notifier = ref.read(savingsGoalProvider.notifier);
              final error = widget.goal == null
                  ? await notifier.create(goal)
                  : await notifier.update(goal);
              if (error != null) {
                setState(() => _error = error);
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ContributionSheet extends ConsumerStatefulWidget {
  final SavingsGoalEntity goal;
  const _ContributionSheet({required this.goal});
  @override
  ConsumerState<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends ConsumerState<_ContributionSheet> {
  final _amount = TextEditingController();
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
            'Aportar a ${widget.goal.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Monto del aporte',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Cuenta de origen'),
          ),
          const SizedBox(height: 8),
          accountsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (_) => const Text('No pudimos cargar tus cuentas.'),
            empty: () => const Text('No tenés cuentas disponibles.'),
            success: (accounts) {
              final available = accounts
                  .where(
                    (account) =>
                        account.isActive && account.id != widget.goal.accountId,
                  )
                  .toList();
              return AppSearchableSingleSelector<AccountEntity>(
                items: available,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                leadingOf: (item) =>
                    Icon(item.icon, color: context.colors.primary),
                value: _account,
                hint: 'Seleccionar cuenta',
                searchHint: 'Buscar cuentas',
                onChanged: (value) => setState(() => _account = value),
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: TextStyle(color: context.colors.error)),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Registrar aporte',
            onPressed: _account == null
                ? null
                : () async {
                    final amount = double.tryParse(_amount.text) ?? 0;
                    if (amount <= 0) {
                      setState(() => _error = 'Ingresá un aporte válido.');
                      return;
                    }
                    final error = await ref
                        .read(savingsGoalProvider.notifier)
                        .contribute(
                          widget.goal.id,
                          amount,
                          accountId: _account!.id,
                        );
                    if (error != null) {
                      setState(() => _error = error);
                      return;
                    }
                    await PilotLocalStore.recordMetric(
                      'savings_goal_contribution',
                      data: {
                        'scope': widget.goal.scope.name,
                        'accountId': _account!.id,
                      },
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}

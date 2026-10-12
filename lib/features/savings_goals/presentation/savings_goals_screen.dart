import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../app/theme/app_radius.dart';
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

enum _GoalAction { edit, delete }

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  SavingsGoalScope _selectedScope = SavingsGoalScope.private;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsGoalProvider);
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(context),
        tooltip: 'Nueva meta',
        child: const Icon(Icons.add_rounded, size: 34),
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
        data: (goals) {
          final privateGoals = goals
              .where((goal) => goal.scope == SavingsGoalScope.private)
              .toList();
          final sharedGoals = goals
              .where((goal) => goal.scope == SavingsGoalScope.family)
              .toList();
          final showingPrivate = _selectedScope == SavingsGoalScope.private;
          final selectedGoals = showingPrivate ? privateGoals : sharedGoals;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              112,
            ),
            children: [
              _scopeSelector(privateGoals.length, sharedGoals.length),
              const SizedBox(height: AppSpacing.md),
              _encouragementBanner(),
              const SizedBox(height: AppSpacing.lg),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previousChildren, ?currentChild],
                  ),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedScope),
                    child: _section(
                      context,
                      showingPrivate ? 'Metas privadas' : 'Metas compartidas',
                      selectedGoals,
                      _selectedScope,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _adviceBanner(),
            ],
          );
        },
      ),
    );
  }

  Widget _scopeSelector(int privateCount, int sharedCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        children: [
          Expanded(
            child: _scopeOption(
              scope: SavingsGoalScope.private,
              icon: Icons.person_rounded,
              label: 'Privadas ($privateCount)',
            ),
          ),
          Expanded(
            child: _scopeOption(
              scope: SavingsGoalScope.family,
              icon: Icons.groups_2_outlined,
              label: 'Compartidas ($sharedCount)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _scopeOption({
    required SavingsGoalScope scope,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedScope == scope;
    final foreground = selected ? Colors.white : context.colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: AppRadius.pillRadius,
        onTap: () => _goToScope(scope),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected ? context.colors.primary : Colors.transparent,
            borderRadius: AppRadius.pillRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToScope(SavingsGoalScope scope) {
    if (_selectedScope == scope) return;
    setState(() => _selectedScope = scope);
  }

  Widget _encouragementBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.successBg.withValues(alpha: 0.72),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(Icons.eco_outlined, color: context.colors.primary, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pequeños aportes, grandes logros',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tus metas te acercan al futuro que querés.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<SavingsGoalEntity> goals,
    SavingsGoalScope scope,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        if (goals.isEmpty)
          _emptySection(scope)
        else
          ...goals.map(
            (goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _goalCard(goal),
            ),
          ),
      ],
    );
  }

  Widget _emptySection(SavingsGoalScope scope) {
    final shared = scope == SavingsGoalScope.family;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(
            shared ? Icons.groups_2_outlined : Icons.savings_outlined,
            color: context.colors.primary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            shared
                ? 'Todavía no tenés metas compartidas.'
                : 'Todavía no tenés metas privadas.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(SavingsGoalEntity goal) {
    final shared = goal.scope == SavingsGoalScope.family;
    final progress = goal.progress.clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final subtitle = goal.accountName?.trim().isNotEmpty == true
        ? goal.accountName!
        : shared
        ? 'Una meta para alcanzar juntos'
        : 'Tu ahorro personal';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: context.colors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shared ? Icons.groups_2_outlined : Icons.shield_outlined,
                  color: context.colors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (shared) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.successBg,
                              borderRadius: AppRadius.pillRadius,
                            ),
                            child: Text(
                              'Compartida',
                              style: TextStyle(
                                color: context.colors.primaryVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_GoalAction>(
                tooltip: 'Opciones de la meta',
                onSelected: (action) => _handleGoalAction(action, goal),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _GoalAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Editar'),
                    ),
                  ),
                  if (goal.savedAmount <= 0)
                    const PopupMenuItem(
                      value: _GoalAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Eliminar'),
                      ),
                    ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pillRadius,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: context.colors.successBg,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$percentage%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _amountDetail(
                  label: 'Monto actual',
                  amount: CurrencyFormatter.format(goal.savedAmount),
                  supporting:
                      'de ${CurrencyFormatter.format(goal.targetAmount)}',
                ),
              ),
              Container(
                width: 1,
                height: 78,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: context.colors.border,
              ),
              Expanded(
                child: _amountDetail(
                  label: 'Te faltan',
                  amount: CurrencyFormatter.format(goal.remaining),
                  supporting:
                      'Objetivo: ${DateFormatter.short(goal.targetDate)}',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _openCreate(context, goal),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _openContribution(context, goal),
                    child: const Text('Registrar aporte'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountDetail({
    required String label,
    required String amount,
    required String supporting,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Expanded(
              child: Text(
                supporting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adviceBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.successBg.withValues(alpha: 0.68),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: context.colors.primary,
            size: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consejo',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'La constancia hoy construye tus grandes planes mañana.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoalAction(
    _GoalAction action,
    SavingsGoalEntity goal,
  ) async {
    switch (action) {
      case _GoalAction.edit:
        _openCreate(context, goal);
      case _GoalAction.delete:
        final error = await ref
            .read(savingsGoalProvider.notifier)
            .delete(goal.id);
        if (error != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
    }
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
    text: CurrencyFormatter.inputValue(widget.goal?.targetAmount),
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
            inputFormatters: const [CurrencyInputFormatter()],
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
                  CurrencyFormatter.parse(_target.text) <= 0 ||
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
                targetAmount: CurrencyFormatter.parse(_target.text),
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
            inputFormatters: const [CurrencyInputFormatter()],
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
                    final amount = CurrencyFormatter.parse(_amount.text);
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

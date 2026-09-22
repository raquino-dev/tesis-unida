import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/presentation/screens/add_edit_movement_screen.dart';
import '../../movements/presentation/viewmodels/movement_providers.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../movements/presentation/widgets/movement_filter_sheet.dart';
import '../domain/account_entity.dart';
import 'account_list_screen.dart';
import 'account_providers.dart';

final _accountMovementsProvider = FutureProvider.autoDispose
    .family<List<MovementEntity>, String>((ref, id) async {
      final movements = await ref
          .watch(movementRepositoryProvider)
          .getMovements(accountId: id);
      return movements.where((movement) => movement.account.id == id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });

class AccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  final _search = TextEditingController();
  late MovementFilters _filters = MovementFilters(accountId: widget.accountId);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(accountListViewModelProvider.notifier).load();
    ref.invalidate(_accountMovementsProvider(widget.accountId));
    try {
      await ref.read(_accountMovementsProvider(widget.accountId).future);
    } catch (_) {
      // El provider muestra el error y permite volver a intentar con pull to refresh.
    }
  }

  Future<void> _addMovement() async {
    await context.push(
      AppRoutes.addMovement,
      extra: AddMovementArgs(initialAccountId: widget.accountId),
    );
    if (mounted) await _refresh();
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovementFilterSheet(
        initialFilters: _filters,
        lockedAccountId: widget.accountId,
        onApply: (filters) => setState(
          () => _filters = filters.copyWith(accountId: widget.accountId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountListViewModelProvider);
    final movements = ref.watch(_accountMovementsProvider(widget.accountId));

    final account = accounts.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (items) =>
          items.where((item) => item.id == widget.accountId).firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta'),
        actions: [
          if (account != null)
            PopupMenuButton<String>(
              tooltip: 'Opciones de cuenta',
              onSelected: (action) async {
                if (action == 'edit') {
                  await showAccountEditorSheet(context, account: account);
                  if (mounted) await _refresh();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar cuenta')),
              ],
            ),
        ],
      ),
      floatingActionButton: account?.isActive == true
          ? FloatingActionButton(
              onPressed: _addMovement,
              tooltip: 'Añadir movimiento a ${account!.name}',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: accounts.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(
          message: message,
          onRetry: () => ref.read(accountListViewModelProvider.notifier).load(),
        ),
        empty: () => const AppEmptyState(
          title: 'Cuenta no disponible',
          message: 'No encontramos esta cuenta.',
        ),
        success: (_) => account == null
            ? const AppEmptyState(
                title: 'Cuenta no disponible',
                message: 'No encontramos esta cuenta.',
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _AccountHero(account: account),
                    const SizedBox(height: AppSpacing.sm),
                    movements.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const AppEmptyState(
                        title: 'No pudimos cargar los movimientos',
                        message:
                            'Deslizá hacia abajo para intentarlo de nuevo.',
                      ),
                      data: (items) => Column(
                        children: [
                          _MonthlyTotals(movements: items),
                          const SizedBox(height: AppSpacing.md),
                          _movementsPanel(context, items),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _movementsPanel(BuildContext context, List<MovementEntity> items) {
    final colors = context.colors;
    final visible = items.where(_filters.matches).toList();
    final groups = <DateTime, List<MovementEntity>>{};
    for (final movement in visible) {
      final date = movement.date;
      final day = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(day, () => []).add(movement);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Movimientos',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Más filtros',
                onPressed: _openFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _search,
            onChanged: (value) =>
                setState(() => _filters = _filters.copyWith(query: value)),
            decoration: const InputDecoration(
              hintText: 'Buscar movimientos...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppChip(
                  label: 'Todos',
                  selected: _filters.type == null,
                  onTap: () => setState(
                    () => _filters = _filters.copyWith(clearType: true),
                  ),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Ingresos',
                  selected: _filters.type == MovementType.income,
                  onTap: () => setState(
                    () =>
                        _filters = _filters.copyWith(type: MovementType.income),
                  ),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Egresos',
                  selected: _filters.type == MovementType.expense,
                  onTap: () => setState(
                    () => _filters = _filters.copyWith(
                      type: MovementType.expense,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_filters.activeAdvancedCount > 1) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => setState(() {
                _filters = MovementFilters(accountId: widget.accountId);
                _search.clear();
              }),
              child: const Text('Limpiar filtros adicionales'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  items.isEmpty
                      ? 'Esta cuenta todavía no tiene movimientos.'
                      : 'No hay movimientos con estos filtros.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            for (final group in groups.entries) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  DateFormatter.groupLabel(group.key),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final movement in group.value)
                _AccountMovementTile(
                  movement: movement,
                  onTap: () async {
                    await context.push(
                      AppRoutes.movementDetailPath(movement.id),
                    );
                    if (mounted) await _refresh();
                  },
                ),
            ],
        ],
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  final AccountEntity account;
  const _AccountHero({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primaryVariant],
        ),
        borderRadius: AppRadius.lgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(account.icon, color: colors.primary, size: 31),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.type.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(account.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ),
                const Text(
                  'Saldo disponible',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTotals extends StatelessWidget {
  final List<MovementEntity> movements;
  const _MonthlyTotals({required this.movements});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = movements.where(
      (movement) =>
          movement.date.year == now.year && movement.date.month == now.month,
    );
    final income = current
        .where(
          (movement) =>
              movement.type == MovementType.income && !movement.isCardPayment,
        )
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final expense = current
        .where(
          (movement) =>
              movement.type == MovementType.expense || movement.isCardPayment,
        )
        .fold<double>(0, (sum, movement) => sum + movement.amount);

    return Row(
      children: [
        Expanded(
          child: _MonthlyTile(
            label: 'Ingresos del mes',
            amount: income,
            icon: Icons.arrow_upward_rounded,
            color: context.colors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MonthlyTile(
            label: 'Egresos del mes',
            amount: expense,
            icon: Icons.arrow_downward_rounded,
            color: context.colors.error,
          ),
        ),
      ],
    );
  }
}

class _MonthlyTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  const _MonthlyTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(amount),
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMovementTile extends StatelessWidget {
  final MovementEntity movement;
  final VoidCallback onTap;
  const _AccountMovementTile({required this.movement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final income =
        movement.type == MovementType.income && !movement.isCardPayment;
    final category = movement.primaryCategory;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: category.color.withValues(alpha: 0.12),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${category.name} · ${TimeOfDay.fromDateTime(movement.date).format(context)}',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${income ? '+' : '-'}${CurrencyFormatter.format(movement.amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: income ? colors.success : colors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

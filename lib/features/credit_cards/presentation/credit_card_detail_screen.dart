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
import '../../accounts/presentation/account_providers.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/presentation/screens/add_edit_movement_screen.dart';
import '../../movements/presentation/viewmodels/movement_providers.dart';
import '../domain/credit_card_entity.dart';
import 'credit_card_list_screen.dart';
import 'credit_card_providers.dart';

final _creditCardMovementsProvider = FutureProvider.autoDispose
    .family<List<MovementEntity>, String>((ref, cardId) async {
      final movements = await ref
          .watch(movementRepositoryProvider)
          .getMovements();
      return movements
          .where((movement) => movement.creditCardId == cardId)
          .toList()
        ..sort((left, right) => right.date.compareTo(left.date));
    });

class CreditCardDetailScreen extends ConsumerStatefulWidget {
  final String cardId;

  const CreditCardDetailScreen({super.key, required this.cardId});

  @override
  ConsumerState<CreditCardDetailScreen> createState() =>
      _CreditCardDetailScreenState();
}

class _CreditCardDetailScreenState
    extends ConsumerState<CreditCardDetailScreen> {
  final _search = TextEditingController();
  MovementType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(creditCardListViewModelProvider.notifier).load(),
      ref.read(accountListViewModelProvider.notifier).load(),
    ]);
    ref.invalidate(_creditCardMovementsProvider(widget.cardId));
    try {
      await ref.read(_creditCardMovementsProvider(widget.cardId).future);
    } catch (_) {
      // El estado del provider presenta el error en la misma pantalla.
    }
  }

  Future<void> _addMovement(MovementType type) async {
    final cardsState = ref.read(creditCardListViewModelProvider);
    final card = cardsState.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (cards) =>
          cards.where((item) => item.id == widget.cardId).firstOrNull,
    );
    if (card == null) return;
    await context.push(
      AppRoutes.addMovement,
      extra: AddMovementArgs(
        initialType: type,
        initialAccountId: card.account.id,
        initialCreditCardId: card.id,
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _chooseMovementType() async {
    final type = await showModalBottomSheet<MovementType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.remove_circle_outline_rounded,
                color: context.colors.error,
              ),
              title: const Text('Registrar egreso'),
              onTap: () => Navigator.pop(sheetContext, MovementType.expense),
            ),
            ListTile(
              leading: Icon(
                Icons.add_circle_outline_rounded,
                color: context.colors.success,
              ),
              title: const Text('Registrar ingreso'),
              subtitle: const Text('Reintegro o pago de la tarjeta'),
              onTap: () => Navigator.pop(sheetContext, MovementType.income),
            ),
          ],
        ),
      ),
    );
    if (type != null && mounted) await _addMovement(type);
  }

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(creditCardListViewModelProvider);
    final movementsState = ref.watch(
      _creditCardMovementsProvider(widget.cardId),
    );
    final card = cardsState.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (cards) =>
          cards.where((item) => item.id == widget.cardId).firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjeta'),
        actions: [
          if (card != null)
            IconButton(
              tooltip: 'Editar tarjeta',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () async {
                await showCreditCardEditorSheet(context, card: card);
                if (mounted) await _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: card?.account.isActive == true
          ? FloatingActionButton(
              onPressed: _chooseMovementType,
              tooltip: 'Añadir movimiento a ${card!.alias}',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: cardsState.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(
          message: message,
          onRetry: () =>
              ref.read(creditCardListViewModelProvider.notifier).load(),
        ),
        empty: () => const AppEmptyState(
          title: 'Tarjeta no disponible',
          message: 'No encontramos esta tarjeta.',
        ),
        success: (_) => card == null
            ? const AppEmptyState(
                title: 'Tarjeta no disponible',
                message: 'No encontramos esta tarjeta.',
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _CreditCardHero(card: card),
                    const SizedBox(height: AppSpacing.md),
                    movementsState.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const AppEmptyState(
                        title: 'No pudimos cargar los movimientos',
                        message:
                            'Deslizá hacia abajo para intentarlo de nuevo.',
                      ),
                      data: (movements) => _movementsPanel(movements),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _movementsPanel(List<MovementEntity> movements) {
    final colors = context.colors;
    final query = _search.text.trim().toLowerCase();
    final visible = movements.where((movement) {
      if (_type != null && movement.type != _type) return false;
      if (query.isEmpty) return true;
      return movement.description.toLowerCase().contains(query) ||
          movement.categories.any(
            (category) => category.name.toLowerCase().contains(query),
          );
    }).toList();
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
          Text(
            'Movimientos',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar movimientos...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              AppChip(
                label: 'Todos',
                selected: _type == null,
                onTap: () => setState(() => _type = null),
              ),
              AppChip(
                label: 'Ingresos',
                selected: _type == MovementType.income,
                onTap: () => setState(() => _type = MovementType.income),
              ),
              AppChip(
                label: 'Egresos',
                selected: _type == MovementType.expense,
                onTap: () => setState(() => _type = MovementType.expense),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  movements.isEmpty
                      ? 'Esta tarjeta todavía no tiene movimientos.'
                      : 'No hay movimientos con estos filtros.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            for (final group in groups.entries) ...[
              Container(
                width: double.infinity,
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
                _CardMovementTile(
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

class _CreditCardHero extends StatelessWidget {
  final CreditCardEntity card;

  const _CreditCardHero({required this.card});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.alias,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card.account.name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            CurrencyFormatter.format(card.availableLimit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Línea disponible',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: card.usagePercentage,
            minHeight: 7,
            color: Colors.white,
            backgroundColor: Colors.white24,
            borderRadius: AppRadius.pillRadius,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Utilizada ${CurrencyFormatter.format(card.usedLimit)} de ${CurrencyFormatter.format(card.totalLimit)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CardMovementTile extends StatelessWidget {
  final MovementEntity movement;
  final VoidCallback onTap;

  const _CardMovementTile({required this.movement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final income = movement.type == MovementType.income;
    final category = movement.primaryCategory;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.12),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(
          movement.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${income ? '+' : '-'}${CurrencyFormatter.format(movement.amount)}',
              style: TextStyle(
                color: income ? colors.success : colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

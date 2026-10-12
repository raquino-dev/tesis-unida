import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/pilot_local_store.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../credit_cards/domain/credit_card_entity.dart';
import '../../credit_cards/presentation/credit_card_list_screen.dart';
import '../../credit_cards/presentation/credit_card_providers.dart';
import 'account_providers.dart';
import '../domain/account_entity.dart';

const _iconOptions = [
  Icons.payments_outlined,
  Icons.account_balance_outlined,
  Icons.account_balance_wallet_outlined,
  Icons.savings_outlined,
  Icons.credit_card_outlined,
  Icons.credit_card_rounded,
  Icons.smartphone_outlined,
  Icons.wallet_outlined,
];

Future<AccountEntity?> showAccountEditorSheet(
  BuildContext context, {
  AccountEntity? account,
  AccountType? initialType,
}) => showModalBottomSheet<AccountEntity>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _AccountEditorSheet(account: account, initialType: initialType),
);

class AccountListScreen extends ConsumerStatefulWidget {
  const AccountListScreen({super.key});

  @override
  ConsumerState<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends ConsumerState<AccountListScreen> {
  String? _deletingId;

  List<_FinancialProductItem> _orderedItems(
    List<AccountEntity> accounts,
    List<CreditCardEntity> cards,
  ) {
    final linkedCardAccountIds = cards.map((card) => card.account.id).toSet();
    final items = <_FinancialProductItem>[
      ...accounts
          .where(
            (account) =>
                account.type != AccountType.creditCard ||
                !linkedCardAccountIds.contains(account.id),
          )
          .map(_FinancialProductItem.account),
      ...cards.map(_FinancialProductItem.card),
    ];
    final positions = <String, int>{
      for (
        var index = 0;
        index < PilotLocalStore.financialProductsOrder.length;
        index++
      )
        PilotLocalStore.financialProductsOrder[index]: index,
    };
    final originalPositions = <String, int>{
      for (var index = 0; index < items.length; index++)
        items[index].key: index,
    };
    items.sort((left, right) {
      final leftPosition = positions[left.key];
      final rightPosition = positions[right.key];
      if (leftPosition != null && rightPosition != null) {
        return leftPosition.compareTo(rightPosition);
      }
      if (leftPosition != null) return -1;
      if (rightPosition != null) return 1;
      return originalPositions[left.key]!.compareTo(
        originalPositions[right.key]!,
      );
    });
    return items;
  }

  Future<void> _createProduct() async {
    final action = await showModalBottomSheet<_FinancialProductType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Nueva cuenta'),
              onTap: () =>
                  Navigator.pop(sheetContext, _FinancialProductType.account),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Nueva tarjeta de crédito'),
              onTap: () =>
                  Navigator.pop(sheetContext, _FinancialProductType.card),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _FinancialProductType.account) {
      await showAccountEditorSheet(context);
    } else {
      await showCreditCardEditorSheet(context);
    }
  }

  Future<void> _deleteCard(CreditCardEntity card) async {
    setState(() => _deletingId = 'card:${card.id}');
    try {
      await ref.read(creditCardListViewModelProvider.notifier).delete(card.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appErrorMessage(
                error,
                fallback: 'No pudimos eliminar la tarjeta.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountListViewModelProvider);
    final viewModel = ref.read(accountListViewModelProvider.notifier);
    final cardsState = ref.watch(creditCardListViewModelProvider);
    final accounts = state.when(
      loading: () => <AccountEntity>[],
      error: (_) => <AccountEntity>[],
      empty: () => <AccountEntity>[],
      success: (items) => items,
    );
    final cards = cardsState.when(
      loading: () => <CreditCardEntity>[],
      error: (_) => <CreditCardEntity>[],
      empty: () => <CreditCardEntity>[],
      success: (items) => items,
    );
    final loading =
        state.when(
          loading: () => true,
          error: (_) => false,
          empty: () => false,
          success: (_) => false,
        ) ||
        cardsState.when(
          loading: () => true,
          error: (_) => false,
          empty: () => false,
          success: (_) => false,
        );
    final accountError = state.when<String?>(
      loading: () => null,
      error: (message) => message,
      empty: () => null,
      success: (_) => null,
    );
    final cardError = cardsState.when<String?>(
      loading: () => null,
      error: (message) => message,
      empty: () => null,
      success: (_) => null,
    );
    final items = _orderedItems(accounts, cards);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas y tarjetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transferir entre cuentas',
            onPressed: () => context.push(AppRoutes.transfers),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Agregar cuenta o tarjeta',
            onPressed: _createProduct,
          ),
        ],
      ),
      body: loading
          ? const AppLoadingState()
          : accountError != null && accounts.isEmpty
          ? AppErrorState(message: accountError, onRetry: viewModel.load)
          : cardError != null && accounts.isEmpty && cards.isEmpty
          ? AppErrorState(
              message: cardError,
              onRetry: () =>
                  ref.read(creditCardListViewModelProvider.notifier).load(),
            )
          : items.isEmpty
          ? AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sin cuentas ni tarjetas',
              message:
                  'Agregá tu primera cuenta o tarjeta para registrar movimientos.',
              actionLabel: 'Agregar',
              onAction: _createProduct,
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorderItem: (oldIndex, newIndex) async {
                final reordered = [...items];
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await PilotLocalStore.saveFinancialProductsOrder(
                  reordered.map((item) => item.key).toList(),
                );
                if (mounted) setState(() {});
              },
              itemBuilder: (_, index) {
                final item = items[index];
                final colors = context.colors;
                return Padding(
                  key: ValueKey(item.key),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Opacity(
                    opacity: item.isActive ? 1 : 0.5,
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () {
                        if (item.card case final card?) {
                          ref
                              .read(movementListViewModelProvider.notifier)
                              .updateFilters(
                                MovementFilters(creditCardId: card.id),
                              );
                          context.push(AppRoutes.creditCardDetailPath(card.id));
                        } else {
                          final account = item.account!;
                          ref
                              .read(movementListViewModelProvider.notifier)
                              .updateFilters(
                                MovementFilters(accountId: account.id),
                              );
                          context.push(AppRoutes.accountDetailPath(account.id));
                        }
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.16),
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Icon(item.icon, color: colors.primary),
                        ),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!item.isActive)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: AppBadge(
                                  label: 'Inactiva',
                                  tone: AppBadgeTone.neutral,
                                ),
                              ),
                            Text(
                              CurrencyFormatter.formatCompact(item.amount),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_deletingId == item.key)
                              const SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    if (item.card case final card?) {
                                      await showCreditCardEditorSheet(
                                        context,
                                        card: card,
                                      );
                                    } else {
                                      await showAccountEditorSheet(
                                        context,
                                        account: item.account,
                                      );
                                    }
                                  } else if (value == 'delete') {
                                    if (item.card case final card?) {
                                      await _deleteCard(card);
                                      return;
                                    }
                                    setState(() => _deletingId = item.key);
                                    final error = await viewModel.delete(
                                      item.account!.id,
                                    );
                                    if (!context.mounted) return;
                                    setState(() => _deletingId = null);
                                    if (error != null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 12,
                                ),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _FinancialProductType { account, card }

class _FinancialProductItem {
  final AccountEntity? account;
  final CreditCardEntity? card;

  const _FinancialProductItem._({this.account, this.card});

  factory _FinancialProductItem.account(AccountEntity account) =>
      _FinancialProductItem._(account: account);

  factory _FinancialProductItem.card(CreditCardEntity card) =>
      _FinancialProductItem._(card: card);

  String get key =>
      card == null ? 'account:${account!.id}' : 'card:${card!.id}';
  String get name => card?.alias ?? account!.name;
  String get subtitle => card == null
      ? '${account!.type.label}${account!.brand == CardBrand.none ? '' : ' · ${account!.brand.label}'}'
      : 'Tarjeta de crédito · ${card!.account.name}';
  IconData get icon =>
      card == null ? account!.icon : Icons.credit_card_outlined;
  bool get isActive => card?.account.isActive ?? account!.isActive;
  double get amount => card?.availableLimit ?? account!.balance;
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  final AccountEntity? account;
  final AccountType? initialType;
  const _AccountEditorSheet({this.account, this.initialType});

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _balance = TextEditingController(
    text: CurrencyFormatter.inputValue(widget.account?.initialBalance),
  );
  late AccountType _type =
      widget.account?.type ?? widget.initialType ?? AccountType.cash;
  late IconData _icon = widget.account?.icon ?? _type.defaultIcon;
  late CardBrand _brand = widget.account?.brand ?? CardBrand.none;
  late bool _isActive = widget.account?.isActive ?? true;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              Text(
                widget.account != null
                    ? 'Editar cuenta'
                    : widget.initialType == AccountType.debitCard
                    ? 'Nueva tarjeta de débito'
                    : 'Nueva cuenta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nombre',
                controller: _name,
                hint: widget.initialType == AccountType.debitCard
                    ? 'Ej. Débito Continental'
                    : 'Ej. Cuenta principal',
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.initialType == null || widget.account != null) ...[
                Text(
                  'Tipo de cuenta',
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
                  children: AccountType.values
                      .where(
                        (type) =>
                            !type.supportsBrand || type == widget.account?.type,
                      )
                      .map((t) {
                        final selected = t == _type;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _type = t;
                            _icon = t.defaultIcon;
                            if (!t.supportsBrand) _brand = CardBrand.none;
                          }),
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
                              t.label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ícono',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _iconOptions.map((icon) {
                    final selected = icon == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = icon),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.primary.withValues(alpha: 0.2)
                              : colors.surfaceElevated,
                          borderRadius: AppRadius.mdRadius,
                          border: selected
                              ? Border.all(color: colors.primary, width: 1.6)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: selected
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (_type.supportsBrand) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Marca',
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
                  children: CardBrand.values.map((b) {
                    final selected = b == _brand;
                    return GestureDetector(
                      onTap: () => setState(() => _brand = b),
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
                          b.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : colors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Saldo inicial (Gs.)',
                controller: _balance,
                keyboardType: TextInputType.number,
                inputFormatters: const [CurrencyInputFormatter()],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.toggle_on_outlined,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cuenta activa',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
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
                label: widget.account != null
                    ? 'Guardar cambios'
                    : widget.initialType == AccountType.debitCard
                    ? 'Crear tarjeta'
                    : 'Crear cuenta',
                isLoading: _isSaving,
                onPressed: _isSaving || _name.text.trim().isEmpty
                    ? null
                    : () async {
                        setState(() {
                          _isSaving = true;
                          _errorMessage = null;
                        });
                        try {
                          final viewModel = ref.read(
                            accountListViewModelProvider.notifier,
                          );
                          final initialBalance = CurrencyFormatter.parse(
                            _balance.text,
                          );
                          final previous = widget.account;
                          final entity = AccountEntity(
                            id:
                                widget.account?.id ??
                                'acc_${DateTime.now().millisecondsSinceEpoch}',
                            name: _name.text.trim(),
                            type: _type,
                            icon: _icon,
                            brand: _brand,
                            initialBalance: initialBalance,
                            currentBalance: previous?.currentBalance == null
                                ? null
                                : previous!.currentBalance! +
                                      initialBalance -
                                      previous.initialBalance,
                            isActive: _isActive,
                            inUse: widget.account?.inUse ?? false,
                          );
                          final saved = widget.account == null
                              ? await viewModel.create(entity)
                              : await viewModel.update(entity);
                          if (context.mounted) {
                            Navigator.of(context).pop(saved);
                          }
                        } on AppFailure catch (error) {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                              _errorMessage = error.message;
                            });
                          }
                        } catch (error) {
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                              _errorMessage = appErrorMessage(
                                error,
                                fallback: 'No pudimos guardar la cuenta.',
                              );
                            });
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

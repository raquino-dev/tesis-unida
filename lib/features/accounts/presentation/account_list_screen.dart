import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
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

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountListViewModelProvider);
    final viewModel = ref.read(accountListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transferir entre cuentas',
            onPressed: () => context.push(AppRoutes.transfers),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openEditor(context, ref),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) =>
            AppErrorState(message: message, onRetry: viewModel.load),
        empty: () => AppEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Sin cuentas registradas',
          message:
              'Agregá tu primera cuenta para poder registrar movimientos y transferencias.',
          actionLabel: 'Agregar cuenta',
          onAction: () => _openEditor(context, ref),
        ),
        success: (accounts) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: accounts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final a = accounts[index];
            final colors = context.colors;
            return Opacity(
              opacity: a.isActive ? 1 : 0.5,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.16),
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Icon(a.icon, color: colors.primary),
                ),
                title: Text(
                  a.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.type.label,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (a.brand != CardBrand.none) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· ${a.brand.label}',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!a.isActive)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: AppBadge(
                          label: 'Inactiva',
                          tone: AppBadgeTone.neutral,
                        ),
                      ),
                    Text(
                      CurrencyFormatter.formatCompact(a.initialBalance),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _openEditor(context, ref, account: a);
                        } else if (value == 'delete') {
                          final error = await viewModel.delete(a.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref, {
    AccountEntity? account,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountEditorSheet(account: account),
    );
  }
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  final AccountEntity? account;
  const _AccountEditorSheet({this.account});

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _balance = TextEditingController(
    text: (widget.account?.initialBalance ?? 0).toStringAsFixed(0),
  );
  late AccountType _type = widget.account?.type ?? AccountType.cash;
  late IconData _icon = widget.account?.icon ?? _type.defaultIcon;
  late CardBrand _brand = widget.account?.brand ?? CardBrand.none;
  late bool _isActive = widget.account?.isActive ?? true;

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
                widget.account == null ? 'Nueva cuenta' : 'Editar cuenta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nombre',
                controller: _name,
                hint: 'Ej. Débito Continental',
              ),
              const SizedBox(height: AppSpacing.md),
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
                children: AccountType.values.map((t) {
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
                          color: selected ? Colors.white : colors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
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
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: widget.account == null
                    ? 'Crear cuenta'
                    : 'Guardar cambios',
                onPressed: _name.text.trim().isEmpty
                    ? null
                    : () async {
                        final viewModel = ref.read(
                          accountListViewModelProvider.notifier,
                        );
                        final entity = AccountEntity(
                          id:
                              widget.account?.id ??
                              'acc_${DateTime.now().millisecondsSinceEpoch}',
                          name: _name.text.trim(),
                          type: _type,
                          icon: _icon,
                          brand: _brand,
                          initialBalance: double.tryParse(_balance.text) ?? 0,
                          isActive: _isActive,
                          inUse: widget.account?.inUse ?? false,
                        );
                        if (widget.account == null) {
                          await viewModel.create(entity);
                        } else {
                          await viewModel.update(entity);
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

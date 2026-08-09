import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_searchable_selector.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import 'transfer_viewmodel.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  AccountEntity? _from;
  AccountEntity? _to;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accountsState = ref.watch(accountListViewModelProvider);
    final state = ref.watch(transferViewModelProvider);
    final history = ref.watch(transferHistoryProvider);

    ref.listen(transferViewModelProvider, (previous, next) {
      next.when(
        loading: () {},
        empty: () {},
        error: (_) {},
        success: (_) {
          ref.invalidate(transferHistoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transferencia realizada con éxito.')),
          );
          _amount.clear();
          _note.clear();
        },
      );
    });

    final saving = state.when(
      loading: () => true,
      success: (_) => false,
      error: (_) => false,
      empty: () => false,
    );
    final errorMessage = state.when(
      loading: () => null,
      success: (_) => null,
      error: (m) => m,
      empty: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Transferir entre cuentas')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Cuenta de origen',
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
            empty: () => Text(
              'No tenés cuentas registradas todavía.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            success: (accounts) {
              _from ??= accounts.isNotEmpty ? accounts.first : null;
              return _AccountPicker(
                accounts: accounts,
                selectedId: _from?.id,
                onSelect: (a) => setState(() {
                  _from = a;
                  if (_to?.id == a.id) _to = null;
                }),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cuenta de destino',
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
              final options = accounts.where((a) => a.id != _from?.id).toList();
              return _AccountPicker(
                accounts: options,
                selectedId: _to?.id,
                onSelect: (a) => setState(() => _to = a),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Monto (Gs.)',
            controller: _amount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Fecha',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            onTap: _pickDate,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormatter.short(_date),
                  style: TextStyle(color: colors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descripción o nota',
            controller: _note,
            hint: 'Opcional',
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Transferir',
            isLoading: saving,
            onPressed: _from == null || _to == null
                ? null
                : () => ref
                      .read(transferViewModelProvider.notifier)
                      .transfer(
                        fromAccountId: _from!.id,
                        toAccountId: _to!.id,
                        amount: double.tryParse(_amount.text) ?? 0,
                        date: _date,
                        note: _note.text.trim(),
                      ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Historial de transferencias',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (transfers) => transfers.isEmpty
                ? Text(
                    'Todavía no realizaste transferencias.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  )
                : Column(
                    children: transfers.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${t.fromAccount.name} → ${t.toAccount.name}',
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.medium(t.date),
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    if (t.isCancelled)
                                      Text(
                                        'Anulada',
                                        style: TextStyle(
                                          color: colors.error,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(t.amount),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (!t.isCancelled)
                                IconButton(
                                  tooltip: 'Anular transferencia',
                                  icon: const Icon(Icons.undo_rounded),
                                  color: colors.error,
                                  onPressed: () async {
                                    final error = await ref
                                        .read(
                                          transferViewModelProvider.notifier,
                                        )
                                        .cancel(t);
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  },
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
    );
  }
}

class _AccountPicker extends StatelessWidget {
  final List<AccountEntity> accounts;
  final String? selectedId;
  final ValueChanged<AccountEntity> onSelect;

  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) =>
      AppSearchableSingleSelector<AccountEntity>(
        items: accounts,
        idOf: (item) => item.id,
        labelOf: (item) => item.name,
        leadingOf: (item) => Icon(item.icon, color: context.colors.primary),
        value: accounts.where((item) => item.id == selectedId).firstOrNull,
        hint: 'Seleccionar cuenta',
        searchHint: 'Buscar cuentas',
        onChanged: onSelect,
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../domain/credit_card_entity.dart';
import 'credit_card_providers.dart';

class CreditCardListScreen extends ConsumerWidget {
  const CreditCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creditCardListViewModelProvider);
    final viewModel = ref.read(creditCardListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjetas de crédito'),
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
          icon: Icons.credit_card_outlined,
          title: 'Sin tarjetas registradas',
          message:
              'Agregá tu primera tarjeta de crédito para hacer seguimiento de tu línea disponible.',
          actionLabel: 'Agregar tarjeta',
          onAction: () => _openEditor(context),
        ),
        success: (cards) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _CreditCardTile(card: cards[index]),
        ),
      ),
    );
  }

  static void _openEditor(BuildContext context, {CreditCardEntity? card}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreditCardEditorSheet(card: card),
    );
  }
}

class _CreditCardTile extends StatelessWidget {
  final CreditCardEntity card;
  const _CreditCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      elevation: AppCardElevation.elevated,
      onTap: () => CreditCardListScreen._openEditor(context, card: card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(card.account.icon, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.alias,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      card.account.name,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: card.usagePercentage,
              minHeight: 8,
              backgroundColor: colors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(
                card.usagePercentage >= 0.9 ? colors.error : colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(
                context,
                'Línea total',
                CurrencyFormatter.formatCompact(card.totalLimit),
              ),
              _stat(
                context,
                'Utilizada',
                CurrencyFormatter.formatCompact(card.usedLimit),
              ),
              _stat(
                context,
                'Disponible',
                CurrencyFormatter.formatCompact(card.availableLimit),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cierre: ${DateFormatter.short(card.nextClosingDate)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              Text(
                'Vencimiento: ${DateFormatter.short(card.nextDueDate)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CreditCardEditorSheet extends ConsumerStatefulWidget {
  final CreditCardEntity? card;
  const _CreditCardEditorSheet({this.card});

  @override
  ConsumerState<_CreditCardEditorSheet> createState() =>
      _CreditCardEditorSheetState();
}

class _CreditCardEditorSheetState
    extends ConsumerState<_CreditCardEditorSheet> {
  late final _alias = TextEditingController(text: widget.card?.alias ?? '');
  late final _closingDay = TextEditingController(
    text: (widget.card?.closingDay ?? 20).toString(),
  );
  late final _dueDay = TextEditingController(
    text: (widget.card?.dueDay ?? 5).toString(),
  );
  late final _totalLimit = TextEditingController(
    text: widget.card?.totalLimit.toStringAsFixed(0) ?? '',
  );
  late final _usedLimit = TextEditingController(
    text: (widget.card?.usedLimit ?? 0).toStringAsFixed(0),
  );
  AccountEntity? _account;
  String? _errorMessage;

  bool get isEditing => widget.card != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accountsState = ref.watch(accountListViewModelProvider);

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
                    isEditing ? 'Editar tarjeta' : 'Nueva tarjeta',
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
                            .read(creditCardListViewModelProvider.notifier)
                            .delete(widget.card!.id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nombre o alias',
                controller: _alias,
                hint: 'Ej. Compras del hogar',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cuenta asociada',
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
                  _account ??=
                      widget.card?.account ??
                      (accounts.isNotEmpty ? accounts.first : null);
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((a) {
                      final selected = _account?.id == a.id;
                      return GestureDetector(
                        onTap: () => setState(() => _account = a),
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
                            a.name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Día de cierre',
                      controller: _closingDay,
                      keyboardType: TextInputType.number,
                      hint: '1-28',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'Día de vencimiento',
                      controller: _dueDay,
                      keyboardType: TextInputType.number,
                      hint: '1-28',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'El cierre se proyecta automáticamente a los próximos meses según este día.',
                style: TextStyle(color: colors.textMuted, fontSize: 11.5),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Línea total (Gs.)',
                controller: _totalLimit,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Línea utilizada (Gs.)',
                controller: _usedLimit,
                keyboardType: TextInputType.number,
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
                label: isEditing ? 'Guardar cambios' : 'Crear tarjeta',
                onPressed: _alias.text.trim().isEmpty || _account == null
                    ? null
                    : () async {
                        final total = double.tryParse(_totalLimit.text) ?? 0;
                        final used = double.tryParse(_usedLimit.text) ?? 0;
                        final closingDay = int.tryParse(_closingDay.text) ?? 20;
                        final dueDay = int.tryParse(_dueDay.text) ?? 5;
                        if (total <= 0) {
                          setState(
                            () => _errorMessage =
                                'Ingresá una línea total válida.',
                          );
                          return;
                        }
                        if (used > total) {
                          setState(
                            () => _errorMessage =
                                'La línea utilizada no puede superar la línea total.',
                          );
                          return;
                        }
                        if (closingDay < 1 ||
                            closingDay > 28 ||
                            dueDay < 1 ||
                            dueDay > 28) {
                          setState(
                            () => _errorMessage =
                                'Los días de cierre y vencimiento deben estar entre 1 y 28.',
                          );
                          return;
                        }
                        final entity = CreditCardEntity(
                          id: widget.card?.id ?? '',
                          alias: _alias.text.trim(),
                          account: _account!,
                          closingDay: closingDay,
                          dueDay: dueDay,
                          totalLimit: total,
                          usedLimit: used,
                        );
                        final viewModel = ref.read(
                          creditCardListViewModelProvider.notifier,
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

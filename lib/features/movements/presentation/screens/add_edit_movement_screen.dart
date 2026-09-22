import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_searchable_selector.dart';
import '../../../accounts/domain/account_entity.dart';
import '../../../accounts/presentation/account_list_screen.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/domain/category_entity.dart';
import '../../../categories/presentation/category_list_screen.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../credit_cards/presentation/credit_card_list_screen.dart';
import '../../../credit_cards/presentation/credit_card_providers.dart';
import '../../../credit_cards/domain/credit_card_entity.dart';
import '../../domain/movement_entity.dart';
import '../viewmodels/add_movement_viewmodel.dart';
import '../viewmodels/movement_list_viewmodel.dart';
import '../../../reports/presentation/viewmodels/report_viewmodel.dart';
import '../../../predictions/presentation/prediction_viewmodel.dart';
import '../../../dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../../alerts/presentation/alert_providers.dart';
import '../../../../core/services/attachment_picker_service.dart';
import '../../../ocr/domain/ocr_repository.dart';
import '../../../../core/services/pilot_local_store.dart';

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.name,
    required this.account,
    required this.icon,
    this.creditCardId,
  });
  final String id;
  final String name;
  final AccountEntity account;
  final IconData icon;
  final String? creditCardId;

  factory _PaymentOption.account(AccountEntity account) => _PaymentOption(
    id: 'account:${account.id}',
    name: account.name,
    account: account,
    icon: account.icon,
  );

  factory _PaymentOption.card(CreditCardEntity card) => _PaymentOption(
    id: 'card:${card.id}',
    name: card.alias,
    account: card.account,
    creditCardId: card.id,
    icon: Icons.credit_card_outlined,
  );
}

class AddMovementArgs {
  final MovementType? initialType;
  final String? initialAccountId;

  const AddMovementArgs({this.initialType, this.initialAccountId});
}

class AddEditMovementScreen extends ConsumerStatefulWidget {
  final MovementEntity? existing;
  final MovementType? initialType;
  final String? initialAccountId;
  const AddEditMovementScreen({
    super.key,
    this.existing,
    this.initialType,
    this.initialAccountId,
  });

  @override
  ConsumerState<AddEditMovementScreen> createState() =>
      _AddEditMovementScreenState();
}

class _AddEditMovementScreenState extends ConsumerState<AddEditMovementScreen> {
  late MovementType _type =
      widget.existing?.type ?? widget.initialType ?? MovementType.expense;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  List<CategoryEntity> _categories = [];
  AccountEntity? _account;
  AccountEntity? _cardLinkedAccount;
  String? _selectedPaymentId;
  String? _selectedPaymentName;
  CardOperation? _cardOperation;
  bool _attach = false;
  AttachmentType _attachmentType = AttachmentType.image;
  String? _attachmentPath;
  String? _attachmentName;
  String? _documentId;
  late final DateTime _formOpenedAt = DateTime.now();

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _amountController.text = widget.existing!.amount.toStringAsFixed(0);
      _descriptionController.text = widget.existing!.description;
      _categories = List.of(widget.existing!.categories);
      _account = widget.existing!.account;
      _cardOperation = widget.existing!.cardOperation;
      _selectedPaymentId = widget.existing!.creditCardId == null
          ? 'account:${widget.existing!.account.id}'
          : 'card:${widget.existing!.creditCardId}';
      _attach = widget.existing!.hasAttachment;
      _attachmentType = widget.existing!.attachmentType ?? AttachmentType.image;
      _attachmentPath = widget.existing!.attachmentPath;
      _attachmentName = widget.existing!.attachmentName;
      _documentId = widget.existing!.documentId;
    }
  }

  bool get _isCardSelected => _selectedPaymentId?.startsWith('card:') == true;

  CategoryType get _effectiveCategoryType =>
      _type == MovementType.expense || _isCardSelected
      ? CategoryType.expense
      : CategoryType.income;

  void _selectType(MovementType type) {
    setState(() {
      _type = type;
      _cardOperation = _isCardSelected
          ? type == MovementType.expense
                ? CardOperation.purchase
                : CardOperation.refund
          : null;
      if (_cardOperation != CardOperation.payment &&
          _cardLinkedAccount != null) {
        _account = _cardLinkedAccount;
      }
      _categories.removeWhere(
        (category) => !category.type.appliesTo(_effectiveCategoryType),
      );
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<OcrSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, OcrSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Elegir imagen'),
              onTap: () => Navigator.pop(context, OcrSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Elegir PDF'),
              onTap: () => Navigator.pop(context, OcrSource.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Elegir XML SIFEN'),
              onTap: () => Navigator.pop(context, OcrSource.xml),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final selected = await AttachmentPickerService.pick(source);
      if (selected == null || !mounted) return;
      setState(() {
        _attach = true;
        _attachmentPath = selected.path;
        _attachmentName = selected.name;
        _documentId = null;
        _attachmentType = source == OcrSource.pdf
            ? AttachmentType.pdf
            : source == OcrSource.xml
            ? AttachmentType.xml
            : AttachmentType.image;
      });
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<CategoryEntity?> _createCategory() async {
    return showCategoryEditorSheet(context);
  }

  Future<AccountEntity?> _createAccount() async {
    return showAccountEditorSheet(context);
  }

  Future<CreditCardEntity?> _createCreditCard() async {
    final paymentAccount = _account ?? await _createAccount();
    if (paymentAccount == null || !mounted) return null;
    return showCreditCardEditorSheet(context, initialAccount: paymentAccount);
  }

  Future<_PaymentOption?> _createCard() async {
    final cardType = await showModalBottomSheet<AccountType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tarjeta de débito'),
              leading: const Icon(Icons.credit_card_outlined),
              onTap: () =>
                  Navigator.of(sheetContext).pop(AccountType.debitCard),
            ),
            ListTile(
              title: const Text('Tarjeta de crédito'),
              leading: const Icon(Icons.credit_card_rounded),
              onTap: () =>
                  Navigator.of(sheetContext).pop(AccountType.creditCard),
            ),
          ],
        ),
      ),
    );
    if (cardType == null || !mounted) return null;
    if (cardType == AccountType.debitCard) {
      final account = await showAccountEditorSheet(
        context,
        initialType: AccountType.debitCard,
      );
      return account == null ? null : _PaymentOption.account(account);
    }
    final card = await _createCreditCard();
    return card == null ? null : _PaymentOption.card(card);
  }

  Widget _buildCategorySelector(
    List<CategoryEntity> available,
    ButtonStyle fieldStyle,
    AppSemanticColors colors,
  ) => AppSearchableMultiSelector<CategoryEntity>(
    items: available,
    idOf: (item) => item.id,
    labelOf: (item) => item.name,
    leadingOf: (item) => Icon(item.icon, color: item.color),
    leading: Icon(Icons.search_rounded, color: colors.textSecondary),
    style: fieldStyle,
    values: _categories,
    hint: 'Buscar y seleccionar categoría',
    searchHint: 'Buscar categorías',
    sheetTitle: 'Categorías',
    createActions: [
      SelectorCreateAction<CategoryEntity>(
        label: '',
        icon: Icons.add_rounded,
        onCreate: _createCategory,
      ),
    ],
    onChanged: (values) => setState(() => _categories = values),
  );

  Widget _buildPaymentSelector(
    List<AccountEntity> accounts,
    List<CreditCardEntity> cards,
    ButtonStyle fieldStyle,
    AppSemanticColors colors,
  ) {
    final options = [
      ...accounts.map(_PaymentOption.account),
      ...cards
          .where(
            (card) =>
                card.account.isActive &&
                (!isEditing || card.id == widget.existing?.creditCardId),
          )
          .map(_PaymentOption.card),
    ];
    _PaymentOption? selected;
    for (final option in options) {
      if (option.id == _selectedPaymentId ||
          (_selectedPaymentId == null &&
              option.id == 'account:${_account?.id}')) {
        selected = option;
        break;
      }
    }
    return AppSearchableSingleSelector<_PaymentOption>(
      items: options,
      idOf: (item) => item.id,
      labelOf: (item) => item.name,
      leadingOf: (item) => Icon(item.icon, color: colors.primary),
      emptyLeading: Icon(
        Icons.account_balance_wallet_outlined,
        color: colors.primary,
      ),
      style: fieldStyle,
      value: selected,
      hint: 'Seleccionar cuenta o método',
      searchHint: 'Buscar cuentas o métodos de pago',
      sheetTitle: 'Cuentas y tarjetas',
      applySelection: true,
      enabled: !isEditing || widget.existing?.creditCardId == null,
      createActions: [
        SelectorCreateAction<_PaymentOption>(
          label: 'Nueva cuenta',
          icon: Icons.account_balance_wallet_outlined,
          onCreate: () async {
            final account = await _createAccount();
            return account == null ? null : _PaymentOption.account(account);
          },
        ),
        SelectorCreateAction<_PaymentOption>(
          label: 'Nueva tarjeta',
          icon: Icons.credit_card_outlined,
          onCreate: _createCard,
        ),
      ],
      onChanged: (value) => setState(() {
        _selectedPaymentId = value.id;
        _selectedPaymentName = value.name;
        _account = value.account;
        _cardLinkedAccount = value.creditCardId == null ? null : value.account;
        _cardOperation = value.creditCardId == null
            ? null
            : _type == MovementType.expense
            ? CardOperation.purchase
            : CardOperation.refund;
        _categories.removeWhere(
          (category) => !category.type.appliesTo(_effectiveCategoryType),
        );
      }),
    );
  }

  Widget _buildCardOperationSelector(
    List<AccountEntity> accounts,
    AppSemanticColors colors,
  ) {
    if (!_isCardSelected || _type != MovementType.income) {
      return const SizedBox.shrink();
    }
    final operation = _cardOperation ?? CardOperation.refund;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('¿Qué tipo de ingreso es?'),
          const SizedBox(height: 8),
          SegmentedButton<CardOperation>(
            segments: const [
              ButtonSegment(
                value: CardOperation.refund,
                icon: Icon(Icons.replay_rounded),
                label: Text('Reintegro'),
              ),
              ButtonSegment(
                value: CardOperation.payment,
                icon: Icon(Icons.payments_outlined),
                label: Text('Pago de tarjeta'),
              ),
            ],
            selected: {operation},
            onSelectionChanged: isEditing
                ? null
                : (selection) => setState(() {
                    _cardOperation = selection.first;
                    _account = selection.first == CardOperation.payment
                        ? accounts
                                  .where(
                                    (account) =>
                                        account.id == _cardLinkedAccount?.id,
                                  )
                                  .firstOrNull ??
                              accounts.firstOrNull
                        : _cardLinkedAccount;
                  }),
          ),
          if (operation == CardOperation.payment) ...[
            const SizedBox(height: 14),
            const _FieldLabel('Cuenta desde la que pagaste'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: accounts.any((item) => item.id == _account?.id)
                  ? _account!.id
                  : null,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                ),
              ),
              items: accounts
                  .map(
                    (account) => DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                  )
                  .toList(),
              onChanged: isEditing
                  ? null
                  : (id) => setState(() {
                      _account = accounts
                          .where((item) => item.id == id)
                          .firstOrNull;
                    }),
            ),
            const SizedBox(height: 6),
            Text(
              'El pago reduce la deuda de la tarjeta y el saldo de esta cuenta.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'El reintegro reduce la deuda de la tarjeta sin mover dinero de una cuenta.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(categoryListViewModelProvider);
    final accountsState = ref.watch(accountListViewModelProvider);
    final cardsState = ref.watch(creditCardListViewModelProvider);
    final addState = ref.watch(addMovementViewModelProvider);

    ref.listen(addMovementViewModelProvider, (previous, next) {
      next.when(
        loading: () {},
        empty: () {},
        error: (_) {},
        success: (_) {
          if (!isEditing) {
            PilotLocalStore.recordMetric(
              'movement_registered',
              data: {
                'durationSeconds': DateTime.now()
                    .difference(_formOpenedAt)
                    .inSeconds,
                'type': _type.name,
                'withAttachment': _attach,
              },
            );
          }
          ref.read(movementListViewModelProvider.notifier).load();
          ref.read(accountListViewModelProvider.notifier).load();
          ref.read(creditCardListViewModelProvider.notifier).load();
          ref.read(reportViewModelProvider.notifier).load();
          ref.read(predictionViewModelProvider.notifier).load();
          ref.read(dashboardViewModelProvider.notifier).load();
          ref.read(alertListViewModelProvider.notifier).load();
          Navigator.of(context).maybePop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Movimiento actualizado.'
                    : 'Movimiento guardado con éxito.',
              ),
            ),
          );
        },
      );
    });

    final saving = addState.when(
      loading: () => true,
      success: (_) => false,
      error: (_) => false,
      empty: () => false,
    );
    final errorMessage = addState.when(
      loading: () => null,
      success: (_) => null,
      error: (m) => m,
      empty: () => null,
    );

    final fieldStyle = OutlinedButton.styleFrom(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      side: BorderSide(color: colors.border),
      minimumSize: const Size.fromHeight(58),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar movimiento' : 'Añadir movimiento'),
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _confirmDelete(context),
                ),
              ]
            : null,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 56,
            child: AppButton(
              label: isEditing ? 'Guardar cambios' : 'Guardar movimiento',
              isLoading: saving,
              onPressed: _account == null
                  ? null
                  : () => ref
                        .read(addMovementViewModelProvider.notifier)
                        .submit(
                          existingId: widget.existing?.id,
                          type: _type,
                          amount: double.tryParse(_amountController.text) ?? 0,
                          date: _date,
                          categories: _categories,
                          account: _account!,
                          creditCardId:
                              _selectedPaymentId?.startsWith('card:') == true
                              ? _selectedPaymentId!.substring(5)
                              : null,
                          cardOperation: _cardOperation,
                          description: _descriptionController.text.trim(),
                          hasAttachment: _attach,
                          attachmentType: _attach ? _attachmentType : null,
                          ocrStatus: widget.existing?.ocrStatus,
                          attachmentPath: _attach ? _attachmentPath : null,
                          attachmentName: _attach ? _attachmentName : null,
                          documentId: _attach ? _documentId : null,
                        ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'Gasto',
                      selected: _type == MovementType.expense,
                      icon: Icons.remove_rounded,
                      onTap: () => _selectType(MovementType.expense),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeToggle(
                      label: 'Ingreso',
                      selected: _type == MovementType.income,
                      icon: Icons.add_rounded,
                      onTap: () => _selectType(MovementType.income),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _FieldLabel('Monto (Gs.)'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _inputDecoration(
                  context,
                  hint: '0',
                  leading: Icons.monetization_on_outlined,
                  highlighted: true,
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel('Fecha'),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickDate,
                style: fieldStyle,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(DateFormatter.short(_date))),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Categoría'),
              const SizedBox(height: 8),
              categoriesState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_) => Text(
                  'No pudimos cargar tus categorías.',
                  style: TextStyle(color: colors.textSecondary),
                ),
                empty: () => _buildCategorySelector([], fieldStyle, colors),
                success: (categories) {
                  final categoryType = _effectiveCategoryType;
                  final available = categories
                      .where((c) => c.type.appliesTo(categoryType))
                      .toList();
                  final suggestions = available.take(3).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategorySelector(available, fieldStyle, colors),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in suggestions) ...[
                                _CategorySuggestion(
                                  category: category,
                                  selected: _categories.any(
                                    (item) => item.id == category.id,
                                  ),
                                  onTap: () => setState(() {
                                    if (_categories.any(
                                      (item) => item.id == category.id,
                                    )) {
                                      _categories.removeWhere(
                                        (item) => item.id == category.id,
                                      );
                                    } else {
                                      _categories = [..._categories, category];
                                    }
                                  }),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _FieldLabel('Cuenta o método de pago'),
              const SizedBox(height: 8),
              accountsState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_) => Text(
                  'No pudimos cargar tus cuentas.',
                  style: TextStyle(color: colors.textSecondary),
                ),
                empty: () => _buildPaymentSelector(
                  [],
                  cardsState.when(
                    loading: () => <CreditCardEntity>[],
                    error: (_) => <CreditCardEntity>[],
                    empty: () => <CreditCardEntity>[],
                    success: (cards) => cards,
                  ),
                  fieldStyle,
                  colors,
                ),
                success: (accounts) {
                  final active = accounts.where((a) => a.isActive).toList();
                  _account ??= active
                      .where((a) => a.id == widget.initialAccountId)
                      .firstOrNull;
                  _account ??= active.firstOrNull;
                  final cards = cardsState.when(
                    loading: () => <CreditCardEntity>[],
                    error: (_) => <CreditCardEntity>[],
                    empty: () => <CreditCardEntity>[],
                    success: (cards) => cards,
                  );
                  final selectedCard = cards
                      .where((card) => 'card:${card.id}' == _selectedPaymentId)
                      .firstOrNull;
                  _cardLinkedAccount ??= selectedCard?.account;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPaymentSelector(active, cards, fieldStyle, colors),
                      _buildCardOperationSelector(active, colors),
                    ],
                  );
                },
              ),
              if (_account != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Seleccionado: ${_selectedPaymentName ?? _account!.name}',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: _FieldLabel('Descripción')),
                  Text(
                    'Opcional',
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                decoration: _inputDecoration(
                  context,
                  hint: 'Añade un detalle sobre este movimiento...',
                  leading: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 20),
              _FieldLabel('Adjuntar comprobante'),
              const SizedBox(height: 8),
              CustomPaint(
                painter: _DashedOutlinePainter(colors.border),
                child: Material(
                  color: colors.surface,
                  borderRadius: AppRadius.mdRadius,
                  child: InkWell(
                    onTap: _pickAttachment,
                    borderRadius: AppRadius.mdRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            color: colors.textSecondary,
                            size: 25,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _attach
                                      ? (_attachmentName ??
                                            'Comprobante adjuntado')
                                      : 'Adjuntar comprobante',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _attach
                                      ? 'Archivo listo · ${_attachmentType.name.toUpperCase()}'
                                      : 'Fotos, PDFs o imágenes',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colors.surfaceElevated,
                            child: Icon(
                              _attach ? Icons.check_rounded : Icons.add_rounded,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_attach)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _attach = false;
                      _attachmentPath = null;
                      _attachmentName = null;
                      _documentId = null;
                    }),
                    child: const Text('Quitar adjunto'),
                  ),
                ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData leading,
    bool highlighted = false,
  }) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(
        color: highlighted ? colors.primary : colors.border,
        width: highlighted ? 1.4 : 1,
      ),
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        leading,
        color: highlighted ? colors.primary : colors.textSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: border,
      border: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.8),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text(
          'Esta acción no se puede deshacer. ¿Querés eliminar este movimiento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(movementListViewModelProvider.notifier)
                  .deleteMovement(widget.existing!.id);
              ref.read(accountListViewModelProvider.notifier).load();
              ref.read(creditCardListViewModelProvider.notifier).load();
              ref.read(reportViewModelProvider.notifier).load();
              ref.read(predictionViewModelProvider.notifier).load();
              ref.read(dashboardViewModelProvider.notifier).load();
              ref.read(alertListViewModelProvider.notifier).load();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.mdRadius,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: selected ? null : colors.surface,
          gradient: selected
              ? LinearGradient(colors: [colors.primary, colors.primaryVariant])
              : null,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: selected ? Colors.white : colors.textMuted,
                child: Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.primary : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : colors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: context.colors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _CategorySuggestion extends StatelessWidget {
  const _CategorySuggestion({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final CategoryEntity category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: category.color.withValues(alpha: selected ? 0.22 : 0.12),
      borderRadius: AppRadius.pillRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            border: selected
                ? Border.all(color: category.color, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

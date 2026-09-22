import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/abstract_backdrop.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_searchable_selector.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../accounts/presentation/account_list_screen.dart';
import '../../../categories/domain/category_entity.dart';
import '../../../categories/presentation/category_list_screen.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../credit_cards/presentation/credit_card_list_screen.dart';
import '../../../movements/domain/movement_entity.dart';
import '../../../movements/presentation/viewmodels/add_movement_viewmodel.dart';
import '../../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../domain/ocr_repository.dart';
import '../../domain/ocr_result_entity.dart';
import '../viewmodels/ocr_viewmodel.dart';
import '../widgets/ocr_processing_illustration.dart';
import '../../../subscription/domain/subscription_entity.dart';
import '../../../subscription/presentation/premium_gate.dart';
import '../../../../core/services/pilot_local_store.dart';

class OcrScanScreen extends ConsumerWidget {
  const OcrScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ocrViewModelProvider);
    final isProcessing = state.when(
      empty: () => false,
      loading: () => true,
      error: (_) => false,
      success: (_) => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: isProcessing ? null : const Text('Escanear factura'),
        leading: isProcessing
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  ref.read(ocrViewModelProvider.notifier).reset();
                  if (context.canPop()) context.pop();
                },
              )
            : null,
      ),
      body: state.when(
        empty: () => PremiumGate(
          capability: PremiumCapability.ocr,
          child: _SourcePicker(),
        ),
        loading: () => OcrProcessingView(
          onCancel: () => ref.read(ocrViewModelProvider.notifier).reset(),
        ),
        error: (message) => AppErrorState(
          message: message,
          onRetry: () => ref.read(ocrViewModelProvider.notifier).reset(),
        ),
        success: (result) => result.status == OcrStatus.failed
            ? AppErrorState(
                message:
                    'No pudimos leer los datos de este comprobante. Probá con otra foto o cargalo manualmente.',
                onRetry: () => ref.read(ocrViewModelProvider.notifier).reset(),
              )
            : _ResultReview(result: result),
      ),
    );
  }
}

class _SourcePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            if (PilotLocalStore.monthlyOcrCount < 3) ...[
              AppCard(
                child: Text(
                  'Plan Free: te quedan ${3 - PilotLocalStore.monthlyOcrCount} comprobantes OCR este mes.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const AbstractBackdrop(height: 200),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Registrá tu gasto en segundos',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Elegí una foto de tu comprobante y completamos los datos automáticamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Tomar foto',
              icon: Icons.photo_camera_outlined,
              onPressed: () => ref
                  .read(ocrViewModelProvider.notifier)
                  .scan(OcrSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Elegir de la galería',
              icon: Icons.image_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => ref
                  .read(ocrViewModelProvider.notifier)
                  .scan(OcrSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cargar archivo PDF',
              icon: Icons.picture_as_pdf_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () =>
                  ref.read(ocrViewModelProvider.notifier).scan(OcrSource.pdf),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Importar comprobante XML SIFEN',
              icon: Icons.code_rounded,
              variant: AppButtonVariant.ghost,
              onPressed: () =>
                  ref.read(ocrViewModelProvider.notifier).scan(OcrSource.xml),
            ),
          ],
        ),
      ),
    );
  }
}

class OcrProcessingView extends StatelessWidget {
  final VoidCallback onCancel;

  const OcrProcessingView({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const OcrProcessingIllustration(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Analizando tu comprobante',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Estamos procesando tu archivo de forma segura y detectando los datos relevantes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      _ProcessingStep(
                        stage: _ProcessingStage.completed,
                        title: 'Archivo recibido',
                        description:
                            'Tu comprobante está listo para procesarse.',
                      ),
                      _ProcessingStep(
                        stage: _ProcessingStage.active,
                        title: 'Extrayendo información',
                        description:
                            'Identificando fecha, comercio, monto y categoría.',
                      ),
                      _ProcessingStep(
                        stage: _ProcessingStage.pending,
                        title: 'Finalizando',
                        description: 'Casi listo, un momento...',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: colors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tu información está segura',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Procesamos el comprobante solo para completar tu movimiento.',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(
                            color: colors.primary.withValues(alpha: 0.26),
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProcessingStage { completed, active, pending }

class _ProcessingStep extends StatelessWidget {
  final _ProcessingStage stage;
  final String title;
  final String description;
  final bool isLast;

  const _ProcessingStep({
    required this.stage,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marker = switch (stage) {
      _ProcessingStage.completed => CircleAvatar(
        radius: 15,
        backgroundColor: colors.primary,
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 21),
      ),
      _ProcessingStage.active => SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: colors.primary,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
        ),
      ),
      _ProcessingStage.pending => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.textMuted, width: 2),
        ),
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Column(
            children: [
              marker,
              if (!isLast)
                Container(
                  width: 2,
                  height: 43,
                  color: stage == _ProcessingStage.completed
                      ? colors.primary.withValues(alpha: 0.38)
                      : colors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultReview extends ConsumerStatefulWidget {
  final OcrResultEntity result;
  const _ResultReview({required this.result});

  @override
  ConsumerState<_ResultReview> createState() => _ResultReviewState();
}

class _ResultReviewState extends ConsumerState<_ResultReview> {
  late final _amount = TextEditingController(
    text: widget.result.amount.toStringAsFixed(0),
  );
  late final _merchant = TextEditingController(text: widget.result.merchant);
  late String _categoryId = widget.result.suggestedCategoryId;
  String? _accountId;
  late DateTime _date = widget.result.date;
  bool _savingDocument = false;
  String? _documentError;

  Future<void> _createCategory() async {
    final created = await showCategoryEditorSheet(context);
    if (created != null && mounted) {
      setState(() => _categoryId = created.id);
    }
  }

  Future<void> _createAccount() async {
    final created = await showAccountEditorSheet(context);
    if (created != null && mounted) setState(() => _accountId = created.id);
  }

  Future<void> _createCreditCard() async {
    final accountsState = ref.read(accountListViewModelProvider);
    var paymentAccount = accountsState.when(
      loading: () => null,
      error: (_) => null,
      empty: () => null,
      success: (accounts) =>
          accounts.where((item) => item.id == _accountId).firstOrNull,
    );
    paymentAccount ??= await showAccountEditorSheet(context);
    if (paymentAccount == null || !mounted) return;
    setState(() => _accountId = paymentAccount!.id);
    final created = await showCreditCardEditorSheet(
      context,
      initialAccount: paymentAccount,
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarjeta “${created.alias}” creada. El movimiento utilizará la cuenta que selecciones.',
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (value != null) setState(() => _date = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(categoryListViewModelProvider);
    final accountsState = ref.watch(accountListViewModelProvider);
    final addState = ref.watch(addMovementViewModelProvider);

    ref.listen(addMovementViewModelProvider, (previous, next) {
      next.when(
        loading: () {},
        empty: () {},
        error: (_) {},
        success: (_) {
          ref.read(movementListViewModelProvider.notifier).load();
          ref.read(accountListViewModelProvider.notifier).load();
          context.go(AppRoutes.dashboard);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movimiento creado a partir de tu comprobante.'),
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
    final isIncomplete = widget.result.status == OcrStatus.incomplete;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isIncomplete)
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Detectamos algunos datos con baja confianza. Revisalos antes de guardar el movimiento.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: colors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Detectamos tu comprobante con ${(widget.result.confidence * 100).toStringAsFixed(0)}% de confianza. Revisá los datos antes de guardar.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.result.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ...widget.result.warnings.map(
                (warning) => Text(
                  '• $warning',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (widget.result.documentName != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.result.documentName!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              label: 'Monto detectado (Gs.)',
              controller: _amount,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Comercio', controller: _merchant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Fecha detectada',
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
                  const Spacer(),
                  const Icon(Icons.edit_calendar_outlined, size: 18),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Categoría sugerida',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            categoriesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (_) => Text(
                'No pudimos cargar tus categorías.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              empty: () => Text(
                'No tenés categorías registradas todavía.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              success: (categories) {
                final available = categories
                    .where((c) => c.type.appliesTo(CategoryType.expense))
                    .toList();
                final selected = available
                    .where((c) => c.id == _categoryId)
                    .firstOrNull;
                return AppSearchableSingleSelector<CategoryEntity>(
                  items: available,
                  idOf: (item) => item.id,
                  labelOf: (item) => item.name,
                  leadingOf: (item) => Icon(item.icon, color: item.color),
                  value: selected,
                  hint: 'Seleccionar categoría',
                  searchHint: 'Buscar categorías',
                  onChanged: (value) => setState(() => _categoryId = value.id),
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _createCategory,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Crear categoría'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cuenta utilizada',
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
                final active = accounts.where((a) => a.isActive).toList();
                _accountId ??= active.isNotEmpty ? active.first.id : null;
                return AppSearchableSingleSelector(
                  items: active,
                  idOf: (item) => item.id,
                  labelOf: (item) => item.name,
                  leadingOf: (item) => Icon(item.icon, color: colors.primary),
                  value: active.where((a) => a.id == _accountId).firstOrNull,
                  hint: 'Seleccionar cuenta',
                  searchHint: 'Buscar cuentas',
                  onChanged: (value) => setState(() => _accountId = value.id),
                );
              },
            ),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  onPressed: _createAccount,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Crear cuenta'),
                ),
                TextButton.icon(
                  onPressed: _createCreditCard,
                  icon: const Icon(Icons.credit_card_outlined, size: 18),
                  label: const Text('Crear tarjeta'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Confirmar y crear movimiento',
              isLoading: saving || _savingDocument,
              onPressed: () async {
                final categories = categoriesState.when(
                  loading: () => null,
                  error: (_) => null,
                  empty: () => null,
                  success: (c) => c,
                );
                final accounts = accountsState.when(
                  loading: () => null,
                  error: (_) => null,
                  empty: () => null,
                  success: (a) => a,
                );
                final category = categories?.firstWhere(
                  (c) => c.id == _categoryId,
                  orElse: () => categories.first,
                );
                final account = accounts?.firstWhere(
                  (a) => a.id == _accountId,
                  orElse: () => accounts.first,
                );
                if (category == null || account == null) return;
                setState(() {
                  _savingDocument = true;
                  _documentError = null;
                });
                OcrResultEntity corrected;
                try {
                  corrected = await ref
                      .read(ocrRepositoryProvider)
                      .correctReceipt(
                        widget.result,
                        amount: double.tryParse(_amount.text) ?? 0,
                        date: _date,
                        merchant: _merchant.text.trim(),
                        categoryId: category.id,
                      );
                } catch (error) {
                  if (!mounted) return;
                  setState(() {
                    _savingDocument = false;
                    _documentError =
                        'No pudimos guardar las correcciones del comprobante.';
                  });
                  return;
                }
                if (!mounted) return;
                setState(() => _savingDocument = false);
                ref
                    .read(addMovementViewModelProvider.notifier)
                    .submit(
                      type: MovementType.expense,
                      amount: double.tryParse(_amount.text) ?? 0,
                      date: _date,
                      categories: [category],
                      account: account,
                      description: _merchant.text.trim(),
                      hasAttachment: true,
                      attachmentType: widget.result.source == OcrSource.xml
                          ? AttachmentType.xml
                          : widget.result.source == OcrSource.pdf
                          ? AttachmentType.pdf
                          : AttachmentType.image,
                      ocrStatus: corrected.status,
                      attachmentPath: widget.result.documentPath,
                      attachmentName: widget.result.documentName,
                      documentId: corrected.documentId,
                    );
              },
            ),
            if (_documentError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _documentError!,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Escanear otra factura',
              variant: AppButtonVariant.ghost,
              onPressed: () => ref.read(ocrViewModelProvider.notifier).reset(),
            ),
          ],
        ),
      ),
    );
  }
}

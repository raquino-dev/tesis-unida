import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/abstract_backdrop.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/domain/category_entity.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../movements/domain/movement_entity.dart';
import '../../../movements/presentation/viewmodels/add_movement_viewmodel.dart';
import '../../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../domain/ocr_repository.dart';
import '../../domain/ocr_result_entity.dart';
import '../viewmodels/ocr_viewmodel.dart';
import '../../../subscription/domain/subscription_entity.dart';
import '../../../subscription/presentation/premium_gate.dart';
import '../../../../core/services/pilot_local_store.dart';

class OcrScanScreen extends ConsumerWidget {
  const OcrScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ocrViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear factura')),
      body: PremiumGate(
        capability: PremiumCapability.ocr,
        child: state.when(
          empty: () => _SourcePicker(),
          loading: () => _ProcessingView(),
          error: (message) => AppErrorState(
            message: message,
            onRetry: () => ref.read(ocrViewModelProvider.notifier).reset(),
          ),
          success: (result) => result.status == OcrStatus.failed
              ? AppErrorState(
                  message:
                      'No pudimos leer los datos de este comprobante. Probá con otra foto o cargalo manualmente.',
                  onRetry: () =>
                      ref.read(ocrViewModelProvider.notifier).reset(),
                )
              : _ResultReview(result: result),
        ),
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

class _ProcessingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colors.primary,
                ),
                Icon(
                  Icons.receipt_long_outlined,
                  color: colors.primary,
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Analizando tu comprobante',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Estamos guardando tu archivo de forma segura y detectando los datos.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
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
              error: (_) => const SizedBox.shrink(),
              empty: () => const SizedBox.shrink(),
              success: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories
                    .where((c) => c.type.appliesTo(CategoryType.expense))
                    .map((c) {
                      final selected = c.id == _categoryId;
                      return GestureDetector(
                        onTap: () => setState(() => _categoryId = c.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? c.color : colors.surfaceElevated,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            c.name,
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
                    })
                    .toList(),
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
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: active.map((a) {
                    final selected = a.id == _accountId;
                    return GestureDetector(
                      onTap: () => setState(() => _accountId = a.id),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              a.icon,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a.name,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Confirmar y crear movimiento',
              isLoading: saving,
              onPressed: () {
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
                      ocrStatus: widget.result.status,
                      attachmentPath: widget.result.documentPath,
                      attachmentName: widget.result.documentName,
                    );
              },
            ),
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

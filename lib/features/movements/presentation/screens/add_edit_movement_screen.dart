import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_searchable_selector.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../accounts/domain/account_entity.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/domain/category_entity.dart';
import '../../../categories/presentation/category_providers.dart';
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

class AddEditMovementScreen extends ConsumerStatefulWidget {
  final MovementEntity? existing;
  final MovementType? initialType;
  const AddEditMovementScreen({super.key, this.existing, this.initialType});

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
  bool _attach = false;
  AttachmentType _attachmentType = AttachmentType.image;
  String? _attachmentPath;
  String? _attachmentName;
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
      _attach = widget.existing!.hasAttachment;
      _attachmentType = widget.existing!.attachmentType ?? AttachmentType.image;
      _attachmentPath = widget.existing!.attachmentPath;
      _attachmentName = widget.existing!.attachmentName;
    }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TypeToggle(
                      label: 'Gasto',
                      selected: _type == MovementType.expense,
                      color: colors.error,
                      onTap: () => setState(() {
                        _type = MovementType.expense;
                        _categories.removeWhere(
                          (c) => !c.type.appliesTo(CategoryType.expense),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TypeToggle(
                      label: 'Ingreso',
                      selected: _type == MovementType.income,
                      color: colors.success,
                      onTap: () => setState(() {
                        _type = MovementType.income;
                        _categories.removeWhere(
                          (c) => !c.type.appliesTo(CategoryType.income),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Monto (Gs.)',
                controller: _amountController,
                keyboardType: TextInputType.number,
                hint: '0',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
              Text(
                'Categorías',
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
                success: (categories) {
                  final movementCategoryType = _type == MovementType.expense
                      ? CategoryType.expense
                      : CategoryType.income;
                  final available = categories
                      .where((c) => c.type.appliesTo(movementCategoryType))
                      .toList();
                  return AppSearchableMultiSelector<CategoryEntity>(
                    items: available,
                    idOf: (item) => item.id,
                    labelOf: (item) => item.name,
                    leadingOf: (item) => Icon(item.icon, color: item.color),
                    values: _categories,
                    hint: 'Buscar y seleccionar categorías',
                    searchHint: 'Buscar categorías',
                    onChanged: (values) => setState(() => _categories = values),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cuenta o método de pago',
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
                  _account ??= active.isNotEmpty ? active.first : null;
                  return AppSearchableSingleSelector<AccountEntity>(
                    items: active,
                    idOf: (item) => item.id,
                    labelOf: (item) => item.name,
                    leadingOf: (item) => Icon(item.icon, color: colors.primary),
                    value: _account,
                    hint: 'Seleccionar cuenta o método',
                    searchHint: 'Buscar cuentas o métodos',
                    onChanged: (value) => setState(() => _account = value),
                  );
                },
              ),
              if (_account != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Seleccionado: ${_account!.name}',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Descripción',
                controller: _descriptionController,
                hint: 'Opcional',
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                onTap: _pickAttachment,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _attach
                            ? (_attachmentName ?? 'Comprobante adjuntado')
                            : 'Adjuntar comprobante',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Icon(
                      _attach
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline_rounded,
                      color: _attach ? colors.success : colors.textMuted,
                    ),
                  ],
                ),
              ),
              if (_attach) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Archivo listo · ${_attachmentType.name.toUpperCase()}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _attach = false;
                        _attachmentPath = null;
                        _attachmentName = null;
                      }),
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  errorMessage,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isEditing ? 'Guardar cambios' : 'Guardar movimiento',
                isLoading: saving,
                onPressed: _account == null
                    ? null
                    : () => ref
                          .read(addMovementViewModelProvider.notifier)
                          .submit(
                            existingId: widget.existing?.id,
                            type: _type,
                            amount:
                                double.tryParse(_amountController.text) ?? 0,
                            date: _date,
                            categories: _categories,
                            account: _account!,
                            description: _descriptionController.text.trim(),
                            hasAttachment: _attach,
                            attachmentType: _attach ? _attachmentType : null,
                            ocrStatus: widget.existing?.ocrStatus,
                            attachmentPath: _attach ? _attachmentPath : null,
                            attachmentName: _attach ? _attachmentName : null,
                          ),
              ),
            ],
          ),
        ),
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
  final Color color;
  final VoidCallback onTap;

  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : colors.surface,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: selected ? color : colors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_searchable_selector.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/presentation/category_providers.dart';
import '../viewmodels/movement_list_viewmodel.dart';

/// Hoja de filtros avanzados de Movimientos: rango de fechas, categoría,
/// cuenta y estado de OCR. Se combinan con el filtro de tipo (chips en la
/// pantalla principal) y pueden restablecerse en conjunto o de forma individual.
class MovementFilterSheet extends ConsumerStatefulWidget {
  final MovementFilters initialFilters;
  const MovementFilterSheet({super.key, required this.initialFilters});

  @override
  ConsumerState<MovementFilterSheet> createState() =>
      _MovementFilterSheetState();
}

class _MovementFilterSheetState extends ConsumerState<MovementFilterSheet> {
  late MovementFilters _draft = widget.initialFilters;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _draft.dateRange,
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(dateRange: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(categoryListViewModelProvider);
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
                    'Filtros',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _draft = _draft.clearAdvanced()),
                    child: const Text('Restablecer'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Rango de fechas',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _draft.dateRange == null
                              ? 'Cualquier fecha'
                              : '${DateFormatter.short(_draft.dateRange!.start)} - ${DateFormatter.short(_draft.dateRange!.end)}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (_draft.dateRange != null)
                        GestureDetector(
                          onTap: () => setState(
                            () =>
                                _draft = _draft.copyWith(clearDateRange: true),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Categoría',
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
                success: (categories) => Column(
                  children: [
                    AppSearchableSingleSelector(
                      items: categories,
                      idOf: (item) => item.id,
                      labelOf: (item) => item.name,
                      leadingOf: (item) => Icon(item.icon, color: item.color),
                      value: categories
                          .where((item) => item.id == _draft.categoryId)
                          .firstOrNull,
                      hint: 'Todas las categorías',
                      searchHint: 'Buscar categorías',
                      onChanged: (value) => setState(
                        () => _draft = _draft.copyWith(categoryId: value.id),
                      ),
                    ),
                    if (_draft.categoryId != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(clearCategory: true),
                          ),
                          child: const Text('Quitar filtro'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cuenta',
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
                success: (accounts) => Column(
                  children: [
                    AppSearchableSingleSelector(
                      items: accounts,
                      idOf: (item) => item.id,
                      labelOf: (item) => item.name,
                      leadingOf: (item) =>
                          Icon(item.icon, color: colors.primary),
                      value: accounts
                          .where((item) => item.id == _draft.accountId)
                          .firstOrNull,
                      hint: 'Todas las cuentas',
                      searchHint: 'Buscar cuentas',
                      onChanged: (value) => setState(
                        () => _draft = _draft.copyWith(accountId: value.id),
                      ),
                    ),
                    if (_draft.accountId != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(
                            () => _draft = _draft.copyWith(clearAccount: true),
                          ),
                          child: const Text('Quitar filtro'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Comprobante OCR',
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
                children: [
                  _ocrOption(context, 'Todos', OcrFilter.any),
                  _ocrOption(context, 'Con OCR', OcrFilter.withOcr),
                  _ocrOption(context, 'Sin OCR', OcrFilter.withoutOcr),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Aplicar filtros',
                onPressed: () {
                  ref
                      .read(movementListViewModelProvider.notifier)
                      .updateFilters(_draft);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ocrOption(BuildContext context, String label, OcrFilter value) {
    final colors = context.colors;
    final selected = _draft.ocrFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _draft = _draft.copyWith(ocrFilter: value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/movement_entity.dart';
import '../viewmodels/movement_list_viewmodel.dart';
import '../widgets/movement_card.dart';
import '../widgets/movement_filter_sheet.dart';

class MovementListScreen extends ConsumerStatefulWidget {
  const MovementListScreen({super.key});

  @override
  ConsumerState<MovementListScreen> createState() => _MovementListScreenState();
}

class _MovementListScreenState extends ConsumerState<MovementListScreen> {
  final _searchController = TextEditingController();

  void _openFilterSheet(MovementFilters filters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MovementFilterSheet(initialFilters: filters),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementListViewModelProvider);
    final viewModel = ref.read(movementListViewModelProvider.notifier);
    final filters = viewModel.filters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Descargar extracto',
            onPressed: () => context.push(AppRoutes.export, extra: filters),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => _openFilterSheet(filters),
                ),
                if (filters.activeAdvancedCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => viewModel.updateFilters(
                viewModel.filters.copyWith(query: value),
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar movimientos',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                AppChip(
                  label: 'Todos',
                  selected: filters.type == null,
                  onTap: () => viewModel.updateFilters(
                    filters.copyWith(clearType: true),
                  ),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Gastos',
                  selected: filters.type == MovementType.expense,
                  onTap: () => viewModel.updateFilters(
                    filters.copyWith(type: MovementType.expense),
                  ),
                ),
                const SizedBox(width: 8),
                AppChip(
                  label: 'Ingresos',
                  selected: filters.type == MovementType.income,
                  onTap: () => viewModel.updateFilters(
                    filters.copyWith(type: MovementType.income),
                  ),
                ),
              ],
            ),
          ),
          if (filters.hasAdvancedFilters) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  if (filters.dateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label:
                            '${DateFormatter.short(filters.dateRange!.start)} - ${DateFormatter.short(filters.dateRange!.end)}',
                        selected: true,
                        onRemove: () => viewModel.updateFilters(
                          filters.copyWith(clearDateRange: true),
                        ),
                      ),
                    ),
                  if (filters.categoryId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: 'Categoría',
                        selected: true,
                        onRemove: () => viewModel.updateFilters(
                          filters.copyWith(clearCategory: true),
                        ),
                      ),
                    ),
                  if (filters.accountId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: 'Cuenta',
                        selected: true,
                        onRemove: () => viewModel.updateFilters(
                          filters.copyWith(clearAccount: true),
                        ),
                      ),
                    ),
                  if (filters.ocrFilter != OcrFilter.any)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: filters.ocrFilter == OcrFilter.withOcr
                            ? 'Con OCR'
                            : 'Sin OCR',
                        selected: true,
                        onRemove: () => viewModel.updateFilters(
                          filters.copyWith(ocrFilter: OcrFilter.any),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: state.when(
              loading: () => const AppLoadingState(),
              error: (message) =>
                  AppErrorState(message: message, onRetry: viewModel.load),
              empty: () => AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: filters.hasAdvancedFilters || filters.type != null
                    ? 'Sin resultados para estos filtros'
                    : 'Todavía no tenés movimientos',
                message: filters.hasAdvancedFilters || filters.type != null
                    ? 'Probá ajustar o restablecer los filtros aplicados.'
                    : 'Registrá el primero para empezar a ver tu resumen.',
                actionLabel: filters.hasAdvancedFilters || filters.type != null
                    ? 'Restablecer filtros'
                    : 'Añadir movimiento',
                onAction: () =>
                    (filters.hasAdvancedFilters || filters.type != null)
                    ? viewModel.updateFilters(const MovementFilters())
                    : context.push(AppRoutes.addMovement),
              ),
              success: (movements) =>
                  _GroupedMovementList(movements: movements),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedMovementList extends StatelessWidget {
  final List<MovementEntity> movements;
  const _GroupedMovementList({required this.movements});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final groups = <String, List<MovementEntity>>{};
    for (final m in movements) {
      final key = DateFormatter.groupLabel(m.date);
      groups.putIfAbsent(key, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                entry.key,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...entry.value.map(
              (m) => MovementCard(
                movement: m,
                onTap: () => context.push(AppRoutes.movementDetailPath(m.id)),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

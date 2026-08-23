import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import 'category_providers.dart';
import '../domain/category_entity.dart';

const _iconOptions = [
  Icons.restaurant_outlined,
  Icons.directions_car_outlined,
  Icons.home_outlined,
  Icons.bolt_outlined,
  Icons.favorite_outline,
  Icons.school_outlined,
  Icons.movie_outlined,
  Icons.shopping_bag_outlined,
  Icons.subscriptions_outlined,
  Icons.savings_outlined,
  Icons.category_outlined,
  Icons.pets_outlined,
];

const _colorOptions = [
  Color(0xFF6868A6),
  Color(0xFF505077),
  Color(0xFF363659),
  Color(0xFF3FA37A),
  Color(0xFFC79A4B),
  Color(0xFFB0555A),
  Color(0xFF5C86B0),
];

Future<CategoryEntity?> showCategoryEditorSheet(
  BuildContext context, {
  CategoryEntity? category,
  CategoryType initialType = CategoryType.expense,
}) => showModalBottomSheet<CategoryEntity>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      _CategoryEditorSheet(category: category, initialType: initialType),
);

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryListViewModelProvider);
    final viewModel = ref.read(categoryListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => showCategoryEditorSheet(context),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) =>
            AppErrorState(message: message, onRetry: viewModel.load),
        empty: () => AppEmptyState(
          title: 'Sin categorías',
          message: 'Creá tu primera categoría para organizar tus movimientos.',
          actionLabel: 'Crear categoría',
          onAction: () => showCategoryEditorSheet(context),
        ),
        success: (categories) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final c = categories[index];
            final colors = context.colors;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(c.icon, color: c.color),
              ),
              title: Text(
                c.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBadge(label: c.type.label, tone: AppBadgeTone.neutral),
                  if (c.inUse) ...[
                    const SizedBox(width: 6),
                    const AppBadge(label: 'En uso', tone: AppBadgeTone.info),
                  ],
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    showCategoryEditorSheet(context, category: c);
                  } else if (value == 'delete') {
                    final error = await viewModel.delete(c.id);
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
            );
          },
        ),
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  final CategoryEntity? category;
  final CategoryType initialType;
  const _CategoryEditorSheet({this.category, required this.initialType});

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late IconData _icon = widget.category?.icon ?? _iconOptions.first;
  late Color _color = widget.category?.color ?? _colorOptions.first;
  late CategoryType _type = widget.category?.type ?? widget.initialType;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
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
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category == null ? 'Nueva categoría' : 'Editar categoría',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nombre',
              controller: _name,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tipo',
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
              children: CategoryType.values.map((t) {
                final selected = t == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceElevated,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontSize: 13,
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
                          ? _color.withValues(alpha: 0.2)
                          : colors.surfaceElevated,
                      borderRadius: AppRadius.mdRadius,
                      border: selected
                          ? Border.all(color: _color, width: 1.6)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: selected ? _color : colors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Color',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _colorOptions.map((color) {
                final selected = color == _color;
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: colors.textPrimary, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
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
              label: widget.category == null
                  ? 'Crear categoría'
                  : 'Guardar cambios',
              onPressed: _name.text.trim().isEmpty && _name.text.isEmpty
                  ? null
                  : () async {
                      final viewModel = ref.read(
                        categoryListViewModelProvider.notifier,
                      );
                      final entity = CategoryEntity(
                        id:
                            widget.category?.id ??
                            'cat_${DateTime.now().millisecondsSinceEpoch}',
                        name: _name.text.trim().isEmpty
                            ? 'Nueva categoría'
                            : _name.text.trim(),
                        icon: _icon,
                        color: _color,
                        type: _type,
                        inUse: widget.category?.inUse ?? false,
                      );
                      CategoryEntity? saved;
                      String? error;
                      if (widget.category == null) {
                        final result = await viewModel.createWithResult(entity);
                        saved = result.entity;
                        error = result.error;
                      } else {
                        error = await viewModel.update(entity);
                        saved = error == null ? entity : null;
                      }
                      if (error != null) {
                        setState(() => _errorMessage = error);
                        return;
                      }
                      if (context.mounted) Navigator.of(context).pop(saved);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

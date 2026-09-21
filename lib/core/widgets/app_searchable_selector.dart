import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extension.dart';

typedef SelectorLabel<T> = String Function(T item);
typedef SelectorLeading<T> = Widget? Function(T item)?;
typedef SelectorId<T> = String Function(T item);

class SelectorCreateAction<T> {
  const SelectorCreateAction({
    required this.label,
    required this.icon,
    required this.onCreate,
  });
  final String label;
  final IconData icon;
  final Future<T?> Function() onCreate;
}

class AppSearchableSingleSelector<T> extends StatelessWidget {
  const AppSearchableSingleSelector({
    super.key,
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.leadingOf,
    this.hint = 'Seleccionar',
    this.searchHint = 'Buscar',
    this.enabled = true,
    this.emptyLeading,
    this.style,
    this.sheetTitle,
    this.createActions = const [],
    this.applySelection = false,
  });

  final List<T> items;
  final SelectorId<T> idOf;
  final SelectorLabel<T> labelOf;
  final T? value;
  final ValueChanged<T> onChanged;
  final SelectorLeading<T> leadingOf;
  final String hint;
  final String searchHint;
  final bool enabled;
  final Widget? emptyLeading;
  final ButtonStyle? style;
  final String? sheetTitle;
  final List<SelectorCreateAction<T>> createActions;
  final bool applySelection;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: !enabled || (items.isEmpty && createActions.isEmpty)
        ? null
        : () async {
            final selected = await _showSingleSelector<T>(
              context,
              items: items,
              idOf: idOf,
              value: value,
              labelOf: labelOf,
              leadingOf: leadingOf,
              searchHint: searchHint,
              sheetTitle: sheetTitle,
              createActions: createActions,
              applySelection: applySelection,
            );
            if (selected != null) onChanged(selected);
          },
    style:
        style ??
        OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
    child: Row(
      children: [
        if ((value != null && leadingOf?.call(value as T) != null) ||
            (value == null && emptyLeading != null)) ...[
          value == null ? emptyLeading! : leadingOf!.call(value as T)!,
          const SizedBox(width: 10),
        ],
        Expanded(child: Text(value == null ? hint : labelOf(value as T))),
        const Icon(Icons.expand_more_rounded),
      ],
    ),
  );
}

class AppSearchableMultiSelector<T> extends StatelessWidget {
  const AppSearchableMultiSelector({
    super.key,
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.values,
    required this.onChanged,
    this.leadingOf,
    this.hint = 'Seleccionar',
    this.searchHint = 'Buscar',
    this.enabled = true,
    this.leading,
    this.style,
    this.sheetTitle,
    this.createActions = const [],
  });

  final List<T> items;
  final SelectorId<T> idOf;
  final SelectorLabel<T> labelOf;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final SelectorLeading<T> leadingOf;
  final String hint;
  final String searchHint;
  final bool enabled;
  final Widget? leading;
  final ButtonStyle? style;
  final String? sheetTitle;
  final List<SelectorCreateAction<T>> createActions;

  @override
  Widget build(BuildContext context) {
    final text = values.isEmpty
        ? hint
        : values.length == 1
        ? labelOf(values.first)
        : '${values.length} seleccionadas';
    return OutlinedButton(
      onPressed: !enabled || (items.isEmpty && createActions.isEmpty)
          ? null
          : () async {
              final selected = await _showMultiSelector<T>(
                context,
                items: items,
                idOf: idOf,
                values: values,
                labelOf: labelOf,
                leadingOf: leadingOf,
                searchHint: searchHint,
                sheetTitle: sheetTitle,
                createActions: createActions,
              );
              if (selected != null) onChanged(selected);
            },
      style:
          style ??
          OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: Text(text)),
          const Icon(Icons.expand_more_rounded),
        ],
      ),
    );
  }
}

Future<T?> _showSingleSelector<T>(
  BuildContext context, {
  required List<T> items,
  required SelectorId<T> idOf,
  required T? value,
  required SelectorLabel<T> labelOf,
  required SelectorLeading<T> leadingOf,
  required String searchHint,
  String? sheetTitle,
  List<SelectorCreateAction<T>> createActions = const [],
  bool applySelection = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _SelectorSheet<T>(
    items: items,
    idOf: idOf,
    labelOf: labelOf,
    leadingOf: leadingOf,
    searchHint: searchHint,
    selectedIds: value == null ? <String>{} : {idOf(value)},
    multiple: false,
    sheetTitle: sheetTitle,
    createActions: createActions,
    applySelection: applySelection,
  ),
);

Future<List<T>?> _showMultiSelector<T>(
  BuildContext context, {
  required List<T> items,
  required SelectorId<T> idOf,
  required List<T> values,
  required SelectorLabel<T> labelOf,
  required SelectorLeading<T> leadingOf,
  required String searchHint,
  String? sheetTitle,
  List<SelectorCreateAction<T>> createActions = const [],
}) => showModalBottomSheet<List<T>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _SelectorSheet<T>(
    items: items,
    idOf: idOf,
    labelOf: labelOf,
    leadingOf: leadingOf,
    searchHint: searchHint,
    selectedIds: values.map(idOf).toSet(),
    multiple: true,
    sheetTitle: sheetTitle,
    createActions: createActions,
  ),
);

class _SelectorSheet<T> extends StatefulWidget {
  const _SelectorSheet({
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.leadingOf,
    required this.searchHint,
    required this.selectedIds,
    required this.multiple,
    required this.sheetTitle,
    required this.createActions,
    this.applySelection = false,
  });
  final List<T> items;
  final SelectorId<T> idOf;
  final SelectorLabel<T> labelOf;
  final SelectorLeading<T> leadingOf;
  final String searchHint;
  final Set<String> selectedIds;
  final bool multiple;
  final String? sheetTitle;
  final List<SelectorCreateAction<T>> createActions;
  final bool applySelection;
  @override
  State<_SelectorSheet<T>> createState() => _SelectorSheetState<T>();
}

class _SelectorSheetState<T> extends State<_SelectorSheet<T>> {
  static const _menuDuration = Duration(milliseconds: 260);
  late final Set<String> _selectedIds = {...widget.selectedIds};
  late final List<T> _items = [...widget.items];
  String _query = '';
  bool _actionsOpen = false;

  Future<void> _create(SelectorCreateAction<T> action) async {
    if (_actionsOpen) setState(() => _actionsOpen = false);
    final item = await action.onCreate();
    if (!mounted || item == null) return;
    setState(() {
      _items.removeWhere(
        (existing) => widget.idOf(existing) == widget.idOf(item),
      );
      _items.add(item);
      if (!widget.multiple) _selectedIds.clear();
      _selectedIds.add(widget.idOf(item));
      _query = '';
    });
  }

  void _apply() {
    final selected = _items
        .where((item) => _selectedIds.contains(widget.idOf(item)))
        .toList();
    if (widget.multiple) {
      Navigator.pop(context, selected);
    } else if (selected.isNotEmpty) {
      Navigator.pop(context, selected.first);
    }
  }

  Widget _paymentAction(BuildContext context, SelectorCreateAction<T> action) {
    final colors = context.colors;
    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.surface,
            shape: CircleBorder(side: BorderSide(color: colors.border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _create(action),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Icon(action.icon, color: colors.primary, size: 27),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSheet(BuildContext context, List<T> visible) {
    final colors = context.colors;
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom + AppSpacing.md;
    return SafeArea(
      child: SizedBox(
        height: media.size.height * .86 + AppSpacing.md * 2,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                bottomInset,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          widget.sheetTitle ?? 'Cuentas y tarjetas',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: widget.searchHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('No encontramos opciones.'))
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              indent: 72,
                              color: colors.border,
                            ),
                            itemBuilder: (context, index) {
                              final item = visible[index];
                              final selected = _selectedIds.contains(
                                widget.idOf(item),
                              );
                              final leading = widget.leadingOf?.call(item);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                tileColor: selected
                                    ? colors.surfaceElevated
                                    : null,
                                leading: leading == null
                                    ? null
                                    : CircleAvatar(
                                        backgroundColor: colors.primary
                                            .withValues(alpha: .10),
                                        child: leading,
                                      ),
                                title: Text(widget.labelOf(item)),
                                trailing: selected
                                    ? CircleAvatar(
                                        radius: 16,
                                        backgroundColor: colors.primary,
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 21,
                                        ),
                                      )
                                    : null,
                                onTap: () => setState(() {
                                  _selectedIds
                                    ..clear()
                                    ..add(widget.idOf(item));
                                }),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 150),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Aplicar selección'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_actionsOpen,
                child: AnimatedOpacity(
                  opacity: _actionsOpen ? 1 : 0,
                  duration: _menuDuration,
                  curve: Curves.easeInOutCubic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _actionsOpen = false),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: .34),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 103 + AppSpacing.md,
              bottom: 153 + bottomInset,
              child: IgnorePointer(
                ignoring: !_actionsOpen,
                child: AnimatedOpacity(
                  opacity: _actionsOpen ? 1 : 0,
                  duration: _menuDuration,
                  curve: Curves.easeInOutCubic,
                  child: AnimatedScale(
                    scale: _actionsOpen ? 1 : .65,
                    duration: _menuDuration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.bottomRight,
                    child: _paymentAction(context, widget.createActions.first),
                  ),
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: 202 + bottomInset,
              child: IgnorePointer(
                ignoring: !_actionsOpen,
                child: AnimatedOpacity(
                  opacity: _actionsOpen ? 1 : 0,
                  duration: _menuDuration,
                  curve: Curves.easeInOutCubic,
                  child: AnimatedScale(
                    scale: _actionsOpen ? 1 : .65,
                    duration: _menuDuration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.bottomRight,
                    child: _paymentAction(context, widget.createActions.last),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4 + AppSpacing.md,
              bottom: 70 + bottomInset,
              child: IconButton.filled(
                tooltip: _actionsOpen
                    ? 'Cerrar opciones'
                    : 'Crear cuenta o tarjeta',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 64),
                ),
                onPressed: () => setState(() => _actionsOpen = !_actionsOpen),
                icon: AnimatedRotation(
                  turns: _actionsOpen ? .125 : 0,
                  duration: _menuDuration,
                  curve: Curves.easeInOutCubic,
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where(
          (item) =>
              widget.labelOf(item).toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    if (widget.applySelection &&
        !widget.multiple &&
        widget.createActions.length == 2) {
      return _buildPaymentSheet(context, visible);
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  (widget.sheetTitle == null ? .72 : .86) -
              MediaQuery.of(context).viewInsets.bottom,
          child: Column(
            children: [
              if (widget.sheetTitle != null) ...[
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        widget.sheetTitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextField(
                autofocus: widget.sheetTitle == null,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: widget.searchHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('No encontramos opciones.'))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final item = visible[index];
                          final selected = _selectedIds.contains(
                            widget.idOf(item),
                          );
                          final leading = widget.leadingOf?.call(item);
                          final decoratedLeading =
                              widget.sheetTitle == null || leading == null
                              ? leading
                              : CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .10),
                                  child: leading,
                                );
                          return widget.multiple || widget.applySelection
                              ? CheckboxListTile(
                                  value: selected,
                                  secondary: decoratedLeading,
                                  title: Text(widget.labelOf(item)),
                                  onChanged: (_) => setState(() {
                                    if (!widget.multiple) _selectedIds.clear();
                                    if (!selected) {
                                      _selectedIds.add(widget.idOf(item));
                                    }
                                    if (widget.multiple && selected) {
                                      _selectedIds.remove(widget.idOf(item));
                                    }
                                  }),
                                )
                              : ListTile(
                                  leading: decoratedLeading,
                                  title: Text(widget.labelOf(item)),
                                  trailing: selected
                                      ? const Icon(Icons.check_rounded)
                                      : null,
                                  onTap: () => Navigator.pop(context, item),
                                );
                        },
                      ),
              ),
              if (widget.createActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_actionsOpen)
                        for (final action in widget.createActions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ActionChip(
                              avatar: Icon(action.icon, size: 19),
                              label: Text(action.label),
                              onPressed: () => _create(action),
                            ),
                          ),
                      IconButton.filled(
                        tooltip: widget.createActions.length == 1
                            ? 'Crear categoría'
                            : 'Crear cuenta o tarjeta',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(52, 52),
                        ),
                        onPressed: () {
                          if (widget.createActions.length == 1) {
                            _create(widget.createActions.single);
                          } else {
                            setState(() => _actionsOpen = !_actionsOpen);
                          }
                        },
                        icon: Icon(
                          _actionsOpen
                              ? Icons.close_rounded
                              : Icons.add_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.multiple || widget.applySelection)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Aplicar selección'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

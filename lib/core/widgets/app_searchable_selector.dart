import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

typedef SelectorLabel<T> = String Function(T item);
typedef SelectorLeading<T> = Widget? Function(T item)?;
typedef SelectorId<T> = String Function(T item);

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

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: !enabled || items.isEmpty
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
            );
            if (selected != null) onChanged(selected);
          },
    style: OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    child: Row(
      children: [
        if (value != null && leadingOf?.call(value as T) != null) ...[
          leadingOf!.call(value as T)!,
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

  @override
  Widget build(BuildContext context) {
    final text = values.isEmpty
        ? hint
        : values.length == 1
        ? labelOf(values.first)
        : '${values.length} seleccionadas';
    return OutlinedButton(
      onPressed: !enabled || items.isEmpty
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
              );
              if (selected != null) onChanged(selected);
            },
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          const Icon(Icons.search_rounded),
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
  });
  final List<T> items;
  final SelectorId<T> idOf;
  final SelectorLabel<T> labelOf;
  final SelectorLeading<T> leadingOf;
  final String searchHint;
  final Set<String> selectedIds;
  final bool multiple;
  @override
  State<_SelectorSheet<T>> createState() => _SelectorSheetState<T>();
}

class _SelectorSheetState<T> extends State<_SelectorSheet<T>> {
  late final Set<String> _selectedIds = {...widget.selectedIds};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.items
        .where(
          (item) =>
              widget.labelOf(item).toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: Column(
            children: [
              TextField(
                autofocus: true,
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
                          return widget.multiple
                              ? CheckboxListTile(
                                  value: selected,
                                  secondary: widget.leadingOf?.call(item),
                                  title: Text(widget.labelOf(item)),
                                  onChanged: (_) => setState(
                                    () => selected
                                        ? _selectedIds.remove(widget.idOf(item))
                                        : _selectedIds.add(widget.idOf(item)),
                                  ),
                                )
                              : ListTile(
                                  leading: widget.leadingOf?.call(item),
                                  title: Text(widget.labelOf(item)),
                                  trailing: selected
                                      ? const Icon(Icons.check_rounded)
                                      : null,
                                  onTap: () => Navigator.pop(context, item),
                                );
                        },
                      ),
              ),
              if (widget.multiple)
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    widget.items
                        .where(
                          (item) => _selectedIds.contains(widget.idOf(item)),
                        )
                        .toList(),
                  ),
                  child: const Text('Aplicar selección'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

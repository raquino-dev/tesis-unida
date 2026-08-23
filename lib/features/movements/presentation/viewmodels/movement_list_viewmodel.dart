import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/movement_entity.dart';
import '../../domain/movement_repository.dart';
import 'movement_providers.dart';

/// Filtro tri-estado: sin preferencia, solo con OCR, solo sin OCR.
enum OcrFilter { any, withOcr, withoutOcr }

class MovementFilters {
  final String query;
  final MovementType? type;
  final String? categoryId;
  final String? accountId;
  final DateTimeRange? dateRange;
  final OcrFilter ocrFilter;

  const MovementFilters({
    this.query = '',
    this.type,
    this.categoryId,
    this.accountId,
    this.dateRange,
    this.ocrFilter = OcrFilter.any,
  });

  bool get hasAdvancedFilters =>
      categoryId != null ||
      accountId != null ||
      dateRange != null ||
      ocrFilter != OcrFilter.any;

  int get activeAdvancedCount =>
      (categoryId != null ? 1 : 0) +
      (accountId != null ? 1 : 0) +
      (dateRange != null ? 1 : 0) +
      (ocrFilter != OcrFilter.any ? 1 : 0);

  MovementFilters copyWith({
    String? query,
    MovementType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    OcrFilter? ocrFilter,
  }) {
    return MovementFilters(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      ocrFilter: ocrFilter ?? this.ocrFilter,
    );
  }

  MovementFilters clearAdvanced() {
    return MovementFilters(query: query, type: type);
  }

  /// Evalúa si un movimiento cumple con todos los filtros activos.
  /// Se reutiliza tanto para la lista de Movimientos como para el cálculo
  /// de extractos, evitando duplicar la lógica de filtrado.
  bool matches(MovementEntity m) {
    if (type != null && m.type != type) return false;
    if (categoryId != null && !m.categories.any((c) => c.id == categoryId)) {
      return false;
    }
    if (accountId != null && m.account.id != accountId) return false;
    if (dateRange != null) {
      final start = DateTime(
        dateRange!.start.year,
        dateRange!.start.month,
        dateRange!.start.day,
      );
      final end = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
      );
      if (m.date.isBefore(start) || m.date.isAfter(end)) return false;
    }
    if (ocrFilter == OcrFilter.withOcr && m.ocrStatus == null) return false;
    if (ocrFilter == OcrFilter.withoutOcr && m.ocrStatus != null) return false;
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final matchesQuery =
          m.description.toLowerCase().contains(q) ||
          m.categories.any((c) => c.name.toLowerCase().contains(q));
      if (!matchesQuery) return false;
    }
    return true;
  }
}

class MovementListViewModel
    extends StateNotifier<ViewState<List<MovementEntity>>> {
  final MovementRepository _repository;
  List<MovementEntity> _all = [];
  MovementFilters _filters = const MovementFilters();

  MovementFilters get filters => _filters;

  MovementListViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      _all = await _repository.getMovements();
      _emit();
    } catch (e) {
      state = ViewState.error(
        appErrorMessage(e, fallback: 'No pudimos cargar tus movimientos.'),
      );
    }
  }

  void updateFilters(MovementFilters filters) {
    _filters = filters;
    _emit();
  }

  void resetAdvancedFilters() {
    _filters = _filters.clearAdvanced();
    _emit();
  }

  void _emit() {
    final results = _all.where(_filters.matches).toList();
    state = results.isEmpty
        ? const ViewState.empty()
        : ViewState.success(results);
  }

  Future<void> deleteMovement(String id) async {
    await _repository.deleteMovement(id);
    await load();
  }
}

final movementListViewModelProvider =
    StateNotifierProvider<
      MovementListViewModel,
      ViewState<List<MovementEntity>>
    >((ref) {
      return MovementListViewModel(ref.watch(movementRepositoryProvider));
    });

import 'package:flutter/material.dart' show DateTimeRange;
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import 'export_entity.dart';

abstract class ExportRepository {
  Future<List<ExportRecord>> getHistory();

  /// Genera un extracto para [range], respetando [filters] (los mismos
  /// filtros combinables del módulo de Movimientos). Incluye ingresos,
  /// egresos y transferencias visibles en ese rango.
  Future<ExportRecord> requestExport({
    required ExportFormat format,
    required DateTimeRange range,
    required MovementFilters filters,
    required String filtersSummary,
  });
}

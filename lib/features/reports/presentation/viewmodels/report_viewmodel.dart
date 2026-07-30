import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../../../../core/utils/view_state.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../data/mock_report_repository.dart';
import '../../domain/report_entity.dart';
import '../../domain/report_repository.dart';
import '../../../movements/presentation/viewmodels/movement_providers.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return MockReportRepository(
    ref.watch(categoryRepositoryProvider),
    ref.watch(movementRepositoryProvider),
  );
});

class ReportViewModel extends StateNotifier<ViewState<ReportEntity>> {
  final Ref _ref;
  ReportRange _range = ReportRange.month;
  ReportRange get range => _range;
  DateTimeRange? _customRange;
  DateTimeRange? get customRange => _customRange;

  ReportViewModel(this._ref) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final report = await _ref
          .read(reportRepositoryProvider)
          .getReport(_range, customRange: _customRange);
      state = ViewState.success(report);
    } catch (_) {
      state = const ViewState.error('No pudimos cargar tus reportes.');
    }
  }

  Future<void> changeRange(ReportRange range) async {
    _range = range;
    await load();
  }

  Future<void> changeCustomRange(DateTimeRange range) async {
    _customRange = range;
    _range = ReportRange.custom;
    await load();
  }
}

final reportViewModelProvider =
    StateNotifierProvider<ReportViewModel, ViewState<ReportEntity>>(
      (ref) => ReportViewModel(ref),
    );

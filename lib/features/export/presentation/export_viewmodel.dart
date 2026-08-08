import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../movements/presentation/viewmodels/movement_providers.dart';
import '../../transfers/presentation/transfer_viewmodel.dart';
import '../data/mock_export_repository.dart';
import '../data/api_export_repository.dart';
import '../domain/export_entity.dart';
import '../domain/export_repository.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiExportRepository(ref.watch(apiClientProvider));
  }
  return MockExportRepository(
    ref.watch(movementRepositoryProvider),
    ref.watch(transferRepositoryProvider),
  );
});

class ExportViewModel extends StateNotifier<ViewState<ExportRecord>> {
  final Ref _ref;
  ExportViewModel(this._ref) : super(const ViewState.empty());

  Future<void> export({
    required ExportFormat format,
    required DateTimeRange range,
    MovementFilters filters = const MovementFilters(),
    required String filtersSummary,
  }) async {
    state = const ViewState.loading();
    try {
      final record = await _ref
          .read(exportRepositoryProvider)
          .requestExport(
            format: format,
            range: range,
            filters: filters,
            filtersSummary: filtersSummary,
          );
      state = ViewState.success(record);
      _ref.invalidate(exportHistoryProvider);
    } catch (error) {
      state = ViewState.error(error.toString());
    }
  }

  void reset() => state = const ViewState.empty();
}

final exportViewModelProvider =
    StateNotifierProvider.autoDispose<ExportViewModel, ViewState<ExportRecord>>(
      (ref) => ExportViewModel(ref),
    );

final exportHistoryProvider = FutureProvider<List<ExportRecord>>(
  (ref) => ref.watch(exportRepositoryProvider).getHistory(),
);

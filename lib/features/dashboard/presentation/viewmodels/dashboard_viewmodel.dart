import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../../recurring_movements/presentation/recurring_movement_providers.dart';
import '../../data/mock_dashboard_repository.dart';
import '../../domain/dashboard_repository.dart';
import '../../domain/dashboard_summary_entity.dart';
import '../../../movements/presentation/viewmodels/movement_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return MockDashboardRepository(
    ref.watch(categoryRepositoryProvider),
    ref.watch(recurringMovementRepositoryProvider),
    ref.watch(movementRepositoryProvider),
  );
});

class DashboardViewModel
    extends StateNotifier<ViewState<DashboardSummaryEntity>> {
  final DashboardRepository _repository;
  DashboardViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final summary = await _repository.getSummary();
      state = ViewState.success(summary);
    } catch (e) {
      state = const ViewState.error('No pudimos cargar tu resumen financiero.');
    }
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<
      DashboardViewModel,
      ViewState<DashboardSummaryEntity>
    >((ref) {
      return DashboardViewModel(ref.watch(dashboardRepositoryProvider));
    });

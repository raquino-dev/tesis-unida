import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_alert_repository.dart';
import '../domain/alert_entity.dart';
import '../domain/alert_repository.dart';
import '../../movements/presentation/viewmodels/movement_providers.dart';

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => MockAlertRepository(ref.watch(movementRepositoryProvider)),
);

class AlertListViewModel extends StateNotifier<ViewState<List<AlertEntity>>> {
  final AlertRepository _repository;
  AlertListViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final alerts = await _repository.getAlerts();
      state = alerts.isEmpty
          ? const ViewState.empty()
          : ViewState.success(alerts);
    } catch (_) {
      state = const ViewState.error('No pudimos cargar tus alertas.');
    }
  }
}

final alertListViewModelProvider =
    StateNotifierProvider<AlertListViewModel, ViewState<List<AlertEntity>>>((
      ref,
    ) {
      return AlertListViewModel(ref.watch(alertRepositoryProvider));
    });

final alertDetailProvider = FutureProvider.family<AlertEntity, String>((
  ref,
  id,
) {
  return ref.watch(alertRepositoryProvider).getAlertById(id);
});

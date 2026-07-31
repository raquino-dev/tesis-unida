import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_prediction_repository.dart';
import '../data/api_prediction_repository.dart';
import '../domain/prediction_entity.dart';
import '../domain/prediction_repository.dart';
import '../../movements/presentation/viewmodels/movement_providers.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiPredictionRepository(ref.watch(apiClientProvider));
  }
  return MockPredictionRepository(ref.watch(movementRepositoryProvider));
});

class PredictionViewModel extends StateNotifier<ViewState<PredictionEntity>> {
  final PredictionRepository _repository;
  PredictionViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.getPrediction());
    } on AppFailure catch (failure) {
      state = failure.code == 'datos_insuficientes'
          ? const ViewState.empty()
          : ViewState.error(failure.message);
    } catch (_) {
      state = const ViewState.error('No pudimos calcular tus predicciones.');
    }
  }
}

final predictionViewModelProvider =
    StateNotifierProvider<PredictionViewModel, ViewState<PredictionEntity>>((
      ref,
    ) {
      return PredictionViewModel(ref.watch(predictionRepositoryProvider));
    });

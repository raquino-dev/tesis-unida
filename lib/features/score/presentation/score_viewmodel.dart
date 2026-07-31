import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_score_repository.dart';
import '../data/api_score_repository.dart';
import '../domain/score_entity.dart';
import '../domain/score_repository.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiScoreRepository(ref.watch(apiClientProvider));
  }
  return MockScoreRepository();
});

class ScoreViewModel extends StateNotifier<ViewState<ScoreEntity>> {
  final ScoreRepository _repository;
  ScoreViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.getScore());
    } on AppFailure catch (failure) {
      state = failure.code == 'datos_insuficientes'
          ? const ViewState.empty()
          : ViewState.error(failure.message);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos calcular tu indicador de salud financiera.',
      );
    }
  }
}

final scoreViewModelProvider =
    StateNotifierProvider<ScoreViewModel, ViewState<ScoreEntity>>((ref) {
      return ScoreViewModel(ref.watch(scoreRepositoryProvider));
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_score_repository.dart';
import '../domain/score_entity.dart';
import '../domain/score_repository.dart';

final scoreRepositoryProvider = Provider<ScoreRepository>(
  (ref) => MockScoreRepository(),
);

class ScoreViewModel extends StateNotifier<ViewState<ScoreEntity>> {
  final ScoreRepository _repository;
  ScoreViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.getScore());
    } catch (_) {
      state = const ViewState.error('No pudimos calcular tu score financiero.');
    }
  }
}

final scoreViewModelProvider =
    StateNotifierProvider<ScoreViewModel, ViewState<ScoreEntity>>((ref) {
      return ScoreViewModel(ref.watch(scoreRepositoryProvider));
    });

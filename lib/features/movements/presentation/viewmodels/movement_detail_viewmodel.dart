import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/movement_entity.dart';
import 'movement_providers.dart';

class MovementDetailViewModel extends StateNotifier<ViewState<MovementEntity>> {
  final Ref _ref;
  final String movementId;

  MovementDetailViewModel(this._ref, this.movementId)
    : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final movement = await _ref
          .read(movementRepositoryProvider)
          .getMovementById(movementId);
      state = ViewState.success(movement);
    } catch (e) {
      state = ViewState.error('No pudimos cargar el movimiento.');
    }
  }

  Future<void> reprocessOcr() async {
    state = const ViewState.loading();
    try {
      final movement = await _ref
          .read(movementRepositoryProvider)
          .reprocessOcr(movementId);
      state = ViewState.success(movement);
    } catch (e) {
      state = const ViewState.error('No pudimos reprocesar el comprobante.');
    }
  }
}

final movementDetailViewModelProvider = StateNotifierProvider.family
    .autoDispose<MovementDetailViewModel, ViewState<MovementEntity>, String>(
      (ref, id) => MovementDetailViewModel(ref, id),
    );

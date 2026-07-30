import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/view_state.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../categories/presentation/category_providers.dart';
import '../data/mock_recurring_movement_repository.dart';
import '../domain/recurring_movement_entity.dart';
import '../domain/recurring_movement_repository.dart';

final recurringMovementRepositoryProvider =
    Provider<RecurringMovementRepository>((ref) {
      return MockRecurringMovementRepository(
        ref.watch(categoryRepositoryProvider),
        ref.watch(accountRepositoryProvider),
      );
    });

class RecurringMovementListViewModel
    extends StateNotifier<ViewState<List<RecurringMovementEntity>>> {
  final RecurringMovementRepository _repository;
  RecurringMovementListViewModel(this._repository)
    : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final recurring = await _repository.getRecurringMovements();
      state = recurring.isEmpty
          ? const ViewState.empty()
          : ViewState.success(recurring);
    } catch (e) {
      state = ViewState.error(e.toString());
    }
  }

  Future<String?> create(RecurringMovementEntity recurring) async {
    try {
      await _repository.createRecurringMovement(recurring);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> update(RecurringMovementEntity recurring) async {
    try {
      await _repository.updateRecurringMovement(recurring);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<void> setStatus(
    RecurringMovementEntity recurring,
    RecurringStatus status,
  ) async {
    await update(recurring.copyWith(status: status));
  }

  Future<void> delete(String id) async {
    await _repository.deleteRecurringMovement(id);
    await load();
  }
}

final recurringMovementListViewModelProvider =
    StateNotifierProvider<
      RecurringMovementListViewModel,
      ViewState<List<RecurringMovementEntity>>
    >((ref) {
      return RecurringMovementListViewModel(
        ref.watch(recurringMovementRepositoryProvider),
      );
    });

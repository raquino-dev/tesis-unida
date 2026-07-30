import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_savings_goal_repository.dart';
import '../domain/savings_goal_entity.dart';
import '../domain/savings_goal_repository.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => MockSavingsGoalRepository(),
);

class SavingsGoalNotifier
    extends StateNotifier<AsyncValue<List<SavingsGoalEntity>>> {
  final SavingsGoalRepository repository;
  SavingsGoalNotifier(this.repository) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.getGoals);
  }

  Future<void> create(SavingsGoalEntity goal) async {
    await repository.createGoal(goal);
    await load();
  }

  Future<void> contribute(String id, double amount) async {
    await repository.contribute(id, amount);
    await load();
  }

  Future<void> delete(String id) async {
    await repository.deleteGoal(id);
    await load();
  }
}

final savingsGoalProvider =
    StateNotifierProvider<
      SavingsGoalNotifier,
      AsyncValue<List<SavingsGoalEntity>>
    >((ref) {
      return SavingsGoalNotifier(ref.watch(savingsGoalRepositoryProvider));
    });

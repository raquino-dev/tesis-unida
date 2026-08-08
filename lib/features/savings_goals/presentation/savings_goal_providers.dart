import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_providers.dart';
import '../data/api_savings_goal_repository.dart';
import '../data/mock_savings_goal_repository.dart';
import '../domain/savings_goal_entity.dart';
import '../domain/savings_goal_repository.dart';

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => AppEnvironment.useApi
      ? ApiSavingsGoalRepository(ref.watch(apiClientProvider))
      : MockSavingsGoalRepository(),
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

  Future<String?> create(SavingsGoalEntity goal) async {
    try {
      await repository.createGoal(goal);
      await load();
      return null;
    } on AppFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> update(SavingsGoalEntity goal) async {
    try {
      await repository.updateGoal(goal);
      await load();
      return null;
    } on AppFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> contribute(
    String id,
    double amount, {
    required String accountId,
  }) async {
    try {
      await repository.contribute(id, amount, accountId: accountId);
      await load();
      return null;
    } on AppFailure catch (error) {
      return error.message;
    }
  }

  Future<String?> delete(String id) async {
    try {
      await repository.deleteGoal(id);
      await load();
      return null;
    } on AppFailure catch (error) {
      return error.message;
    }
  }
}

final savingsGoalProvider =
    StateNotifierProvider<
      SavingsGoalNotifier,
      AsyncValue<List<SavingsGoalEntity>>
    >((ref) {
      return SavingsGoalNotifier(ref.watch(savingsGoalRepositoryProvider));
    });

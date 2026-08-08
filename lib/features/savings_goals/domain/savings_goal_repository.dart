import 'savings_goal_entity.dart';

abstract class SavingsGoalRepository {
  Future<List<SavingsGoalEntity>> getGoals();
  Future<SavingsGoalEntity> createGoal(SavingsGoalEntity goal);
  Future<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal);
  Future<SavingsGoalEntity> contribute(
    String id,
    double amount, {
    required String accountId,
  });
  Future<void> deleteGoal(String id);
}

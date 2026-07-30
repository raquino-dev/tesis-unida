import '../../../core/errors/app_failure.dart';
import '../domain/savings_goal_entity.dart';
import '../domain/savings_goal_repository.dart';

class MockSavingsGoalRepository implements SavingsGoalRepository {
  final List<SavingsGoalEntity> _goals = [
    SavingsGoalEntity(
      id: 'goal_1',
      name: 'Fondo de emergencia',
      targetAmount: 12000000,
      savedAmount: 4800000,
      targetDate: DateTime(2026, 12, 31),
      scope: SavingsGoalScope.private,
    ),
    SavingsGoalEntity(
      id: 'goal_2',
      name: 'Vacaciones familiares',
      targetAmount: 9000000,
      savedAmount: 2250000,
      targetDate: DateTime(2027, 1, 15),
      scope: SavingsGoalScope.family,
    ),
  ];
  int _sequence = 100;

  @override
  Future<List<SavingsGoalEntity>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return List.unmodifiable(_goals);
  }

  @override
  Future<SavingsGoalEntity> createGoal(SavingsGoalEntity goal) async {
    await Future.delayed(const Duration(milliseconds: 450));
    if (goal.targetAmount <= 0) {
      throw const AppFailure('Ingresá un objetivo válido.');
    }
    final created = SavingsGoalEntity(
      id: 'goal_${_sequence++}',
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: goal.savedAmount,
      targetDate: goal.targetDate,
      scope: goal.scope,
    );
    _goals.add(created);
    return created;
  }

  @override
  Future<SavingsGoalEntity> contribute(String id, double amount) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (amount <= 0) throw const AppFailure('Ingresá un aporte válido.');
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index < 0) throw const AppFailure('Meta no encontrada.');
    _goals[index] = _goals[index].copyWith(
      savedAmount: _goals[index].savedAmount + amount,
    );
    return _goals[index];
  }

  @override
  Future<void> deleteGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goals.removeWhere((goal) => goal.id == id);
  }
}

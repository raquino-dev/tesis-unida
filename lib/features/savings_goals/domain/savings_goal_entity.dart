enum SavingsGoalScope { private, family }

class SavingsGoalEntity {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final SavingsGoalScope scope;

  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.scope,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);
  double get remaining =>
      (targetAmount - savedAmount).clamp(0, double.infinity);

  SavingsGoalEntity copyWith({
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    SavingsGoalScope? scope,
  }) {
    return SavingsGoalEntity(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      scope: scope ?? this.scope,
    );
  }
}

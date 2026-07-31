enum SavingsGoalScope { private, family }

class SavingsGoalEntity {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final SavingsGoalScope scope;
  final String? accountId;
  final String? accountName;
  final String? familyGroupId;
  final int version;

  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.scope,
    this.accountId,
    this.accountName,
    this.familyGroupId,
    this.version = 1,
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
    String? accountId,
    String? accountName,
    String? familyGroupId,
    int? version,
  }) {
    return SavingsGoalEntity(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      scope: scope ?? this.scope,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      familyGroupId: familyGroupId ?? this.familyGroupId,
      version: version ?? this.version,
    );
  }
}

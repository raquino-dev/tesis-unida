import '../../categories/domain/category_entity.dart';

enum BudgetStatus { healthy, atRisk, exceeded }

enum BudgetPeriod { weekly, monthly, annual }

extension BudgetPeriodLabel on BudgetPeriod {
  String get label {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Semanal';
      case BudgetPeriod.monthly:
        return 'Mensual';
      case BudgetPeriod.annual:
        return 'Anual';
    }
  }
}

class BudgetEntity {
  final String id;
  final String name;
  final double amount;
  final double spent;
  final BudgetPeriod period;
  final List<CategoryEntity> categories;
  final int version;

  const BudgetEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.spent,
    this.period = BudgetPeriod.monthly,
    this.categories = const [],
    this.version = 1,
  });

  double get remaining => amount - spent;

  double get progress => amount <= 0 ? 0 : (spent / amount).clamp(0, 1.4);

  BudgetStatus get status {
    final ratio = amount <= 0 ? 0 : spent / amount;
    if (ratio > 1) return BudgetStatus.exceeded;
    if (ratio >= 0.85) return BudgetStatus.atRisk;
    return BudgetStatus.healthy;
  }

  BudgetEntity copyWith({
    String? name,
    double? amount,
    double? spent,
    BudgetPeriod? period,
    List<CategoryEntity>? categories,
    int? version,
  }) {
    return BudgetEntity(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      categories: categories ?? this.categories,
      version: version ?? this.version,
    );
  }
}

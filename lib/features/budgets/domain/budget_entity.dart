import '../../categories/domain/category_entity.dart';

enum BudgetStatus { healthy, atRisk, exceeded }

enum BudgetPeriod { monthly, quarterly, annual }

extension BudgetPeriodLabel on BudgetPeriod {
  String get label {
    switch (this) {
      case BudgetPeriod.monthly:
        return 'Mensual';
      case BudgetPeriod.quarterly:
        return 'Trimestral';
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

  const BudgetEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.spent,
    this.period = BudgetPeriod.monthly,
    this.categories = const [],
  });

  double get remaining => amount - spent;

  double get progress => (spent / amount).clamp(0, 1.4);

  BudgetStatus get status {
    final ratio = spent / amount;
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
  }) {
    return BudgetEntity(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      period: period ?? this.period,
      categories: categories ?? this.categories,
    );
  }
}

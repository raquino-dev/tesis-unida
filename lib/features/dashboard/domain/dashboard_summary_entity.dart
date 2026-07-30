import '../../categories/domain/category_entity.dart';

class TopCategorySpend {
  final CategoryEntity category;
  final double amount;
  final double percentage;

  const TopCategorySpend({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class UpcomingRecurringItem {
  final String name;
  final double amount;
  final DateTime date;

  const UpcomingRecurringItem({
    required this.name,
    required this.amount,
    required this.date,
  });
}

class DashboardSummaryEntity {
  final String userName;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double budgetTotal;
  final double budgetAvailable;
  final int financialScore;
  final List<TopCategorySpend> topCategories;
  final List<UpcomingRecurringItem> upcomingRecurring;
  final List<String> alertHighlights;

  const DashboardSummaryEntity({
    required this.userName,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.budgetTotal,
    required this.budgetAvailable,
    required this.financialScore,
    required this.topCategories,
    required this.upcomingRecurring,
    required this.alertHighlights,
  });
}

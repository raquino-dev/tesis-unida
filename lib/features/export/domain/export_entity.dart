import '../../categories/domain/category_entity.dart';

enum ExportFormat { excel, pdf }

/// Subtotal por categoría dentro de un extracto.
class StatementCategorySubtotal {
  final CategoryEntity category;
  final double amount;
  const StatementCategorySubtotal({
    required this.category,
    required this.amount,
  });
}

class ExportRecord {
  final String id;
  final ExportFormat format;
  final String range;
  final DateTime date;
  final bool success;
  final double totalIncome;
  final double totalExpense;
  final double totalTransferred;
  final int movementCount;
  final String filtersSummary;
  final List<StatementCategorySubtotal> categorySubtotals;
  final String? artifactPath;

  const ExportRecord({
    required this.id,
    required this.format,
    required this.range,
    required this.date,
    required this.success,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.totalTransferred = 0,
    this.movementCount = 0,
    this.filtersSummary = 'Sin filtros adicionales',
    this.categorySubtotals = const [],
    this.artifactPath,
  });

  double get netBalance => totalIncome - totalExpense;
}

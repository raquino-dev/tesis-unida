import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';

class ApiReportRepository implements ReportRepository {
  final ApiClient _api;
  final CategoryRepository _categories;
  final MovementRepository? _movements;

  ApiReportRepository(this._api, this._categories, [this._movements]);

  @override
  Future<ReportEntity> getReport(
    ReportRange range, {
    DateTimeRange? customRange,
  }) async {
    final query = <String, String>{'rango': _range(range)};
    if (range == ReportRange.custom && customRange != null) {
      query['desde'] = _date(customRange.start);
      query['hasta'] = _date(customRange.end);
    }
    final uri = Uri(path: '/reportes-financieros', queryParameters: query);
    List<CategoryEntity> categories = const [];
    try {
      categories = await _categories.getCategories();
    } on AppFailure {
      // El reporte local puede usar la categoría incluida en cada movimiento.
    }
    ApiResponse? response;
    Map<String, dynamic> json = const {};
    try {
      response = await _api.get(uri.toString());
      json = response.object;
    } on AppFailure catch (failure) {
      final code = failure.code;
      if (code != 'network_error' && !(code?.startsWith('http_5') ?? false)) {
        rethrow;
      }
    }
    if (response == null || response.headers['x-offline-cache'] == 'true') {
      return _localReport(range, customRange, categories);
    }
    return ReportEntity(
      range: range,
      totalIncome: (json['ingresos'] as num).toDouble(),
      totalExpense: (json['gastos'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      distribution: (json['distribucion'] as List<dynamic>? ?? const []).map((
        item,
      ) {
        final value = item as Map<String, dynamic>;
        final category = categories
            .where((candidate) => candidate.id == value['categoriaId'])
            .firstOrNull;
        return CategoryDistribution(
          category:
              category ??
              CategoryEntity(
                id: value['categoriaId'] as String,
                name: value['nombre'] as String,
                icon: Icons.category_outlined,
                color: Colors.blueGrey,
                type: CategoryType.expense,
                inUse: true,
              ),
          amount: (value['monto'] as num).toDouble(),
          percentage: (value['porcentaje'] as num).toDouble(),
        );
      }).toList(),
      trend: (json['tendencia'] as List<dynamic>? ?? const []).map((item) {
        final value = item as Map<String, dynamic>;
        return MonthlyTrendPoint(
          month: DateTime.parse('${value['periodo']}-01'),
          income: (value['ingresos'] as num).toDouble(),
          expense: (value['gastos'] as num).toDouble(),
        );
      }).toList(),
      insights: (json['observaciones'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }

  Future<ReportEntity> _localReport(
    ReportRange range,
    DateTimeRange? customRange,
    List<CategoryEntity> categories,
  ) async {
    final movementRepository = _movements;
    if (movementRepository == null) {
      throw const AppFailure(
        'Abrí el reporte una vez con conexión antes de consultarlo sin internet.',
        code: 'offline_cache_miss',
      );
    }
    final now = DateTime.now();
    final start = switch (range) {
      ReportRange.week => now.subtract(const Duration(days: 7)),
      ReportRange.month => DateTime(now.year, now.month),
      ReportRange.quarter => now.subtract(const Duration(days: 90)),
      ReportRange.year => DateTime(now.year),
      ReportRange.custom =>
        customRange?.start ?? now.subtract(const Duration(days: 30)),
    };
    final end = range == ReportRange.custom ? customRange?.end ?? now : now;
    final movements = (await movementRepository.getMovements())
        .where(
          (item) =>
              !item.date.isBefore(start) &&
              !item.date.isAfter(end.add(const Duration(days: 1))),
        )
        .toList();
    final income = movements
        .where((item) => item.type == MovementType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseItems = movements
        .where((item) => item.type == MovementType.expense)
        .toList();
    final expense = expenseItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final categoryTotals = <String, double>{};
    for (final movement in expenseItems) {
      for (final category in movement.categories) {
        categoryTotals[category.id] =
            (categoryTotals[category.id] ?? 0) + movement.amount;
      }
    }
    final distribution = categoryTotals.entries.map((entry) {
      final category = categories
          .where((candidate) => candidate.id == entry.key)
          .firstOrNull;
      return CategoryDistribution(
        category:
            category ??
            CategoryEntity(
              id: entry.key,
              name: 'Categoría',
              icon: Icons.category_outlined,
              color: Colors.blueGrey,
              type: CategoryType.expense,
              inUse: true,
            ),
        amount: entry.value,
        percentage: expense == 0 ? 0 : entry.value / expense,
      );
    }).toList();
    final monthly = <DateTime, (double, double)>{};
    for (final movement in movements) {
      final month = DateTime(movement.date.year, movement.date.month);
      final current = monthly[month] ?? (0, 0);
      monthly[month] = movement.type == MovementType.income
          ? (current.$1 + movement.amount, current.$2)
          : (current.$1, current.$2 + movement.amount);
    }
    final trend =
        monthly.entries
            .map(
              (entry) => MonthlyTrendPoint(
                month: entry.key,
                income: entry.value.$1,
                expense: entry.value.$2,
              ),
            )
            .toList()
          ..sort((left, right) => left.month.compareTo(right.month));
    return ReportEntity(
      range: range,
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      distribution: distribution,
      trend: trend,
      insights: const [
        'Reporte calculado con la información disponible en el dispositivo.',
      ],
    );
  }

  String _range(ReportRange value) => switch (value) {
    ReportRange.week => 'semana',
    ReportRange.month => 'mes',
    ReportRange.quarter => 'trimestre',
    ReportRange.year => 'anio',
    ReportRange.custom => 'personalizado',
  };

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

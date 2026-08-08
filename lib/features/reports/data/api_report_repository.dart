import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/report_entity.dart';
import '../domain/report_repository.dart';

class ApiReportRepository implements ReportRepository {
  final ApiClient _api;
  final CategoryRepository _categories;

  ApiReportRepository(this._api, this._categories);

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
    final results = await Future.wait([
      _api.get(uri.toString()),
      _categories.getCategories(),
    ]);
    final json = (results[0] as ApiResponse).object;
    final categories = results[1] as List<CategoryEntity>;
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

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary_entity.dart';

class ApiDashboardRepository implements DashboardRepository {
  final ApiClient _api;
  final AuthRepository _auth;
  final CategoryRepository _categories;

  ApiDashboardRepository(this._api, this._auth, this._categories);

  @override
  Future<DashboardSummaryEntity> getSummary() async {
    final results = await Future.wait([
      _api.get('/tableros-financieros?ambito=privado'),
      _auth.currentUser(),
      _categories.getCategories(),
    ]);
    final json = (results[0] as ApiResponse).object;
    final user = results[1] as dynamic;
    final categories = results[2] as List<CategoryEntity>;
    return DashboardSummaryEntity(
      userName: user.name as String,
      totalIncome: (json['ingresos'] as num).toDouble(),
      totalExpense: (json['gastos'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      budgetTotal: (json['presupuestoTotal'] as num).toDouble(),
      budgetAvailable: (json['presupuestoDisponible'] as num).toDouble(),
      financialScore: (json['scoreFinanciero'] as num).toInt(),
      topCategories:
          (json['categoriasPrincipales'] as List<dynamic>? ?? const []).map((
            item,
          ) {
            final value = item as Map<String, dynamic>;
            final category = categories
                .where((candidate) => candidate.id == value['categoriaId'])
                .firstOrNull;
            return TopCategorySpend(
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
      upcomingRecurring:
          (json['proximosRecurrentes'] as List<dynamic>? ?? const []).map((
            item,
          ) {
            final value = item as Map<String, dynamic>;
            return UpcomingRecurringItem(
              name: value['nombre'] as String,
              amount: (value['monto'] as num).toDouble(),
              date: DateTime.parse(value['fecha'] as String),
            );
          }).toList(),
      alertHighlights: (json['alertasDestacadas'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );
  }
}

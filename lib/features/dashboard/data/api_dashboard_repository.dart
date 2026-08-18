import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../movements/domain/movement_entity.dart';
import '../../movements/domain/movement_repository.dart';
import '../../recurring_movements/domain/recurring_movement_entity.dart';
import '../../recurring_movements/domain/recurring_movement_repository.dart';
import '../domain/dashboard_repository.dart';
import '../domain/dashboard_summary_entity.dart';

class ApiDashboardRepository implements DashboardRepository {
  final ApiClient _api;
  final AuthRepository _auth;
  final CategoryRepository _categories;
  final RecurringMovementRepository? _recurring;
  final MovementRepository? _movements;

  ApiDashboardRepository(
    this._api,
    this._auth,
    this._categories, [
    this._recurring,
    this._movements,
  ]);

  @override
  Future<DashboardSummaryEntity> getSummary() async {
    String userName = 'Usuario';
    List<CategoryEntity> categories = const [];
    try {
      final user = await _auth.currentUser();
      userName = user.name;
    } on AppFailure {
      // El nombre es decorativo; el tablero local sigue siendo utilizable.
    }
    try {
      categories = await _categories.getCategories();
    } on AppFailure {
      // Los movimientos conservan sus categorías embebidas para el fallback.
    }
    ApiResponse? apiResponse;
    Map<String, dynamic> json = const {};
    try {
      apiResponse = await _api.get('/tableros-financieros?ambito=privado');
      json = apiResponse.object;
    } on AppFailure catch (failure) {
      final code = failure.code;
      if (code != 'network_error' && !(code?.startsWith('http_5') ?? false)) {
        rethrow;
      }
    }
    if (apiResponse == null ||
        apiResponse.headers['x-offline-cache'] == 'true') {
      return _localSummary(userName, categories, json);
    }
    return _serverSummary(userName, categories, json);
  }

  DashboardSummaryEntity _serverSummary(
    String userName,
    List<CategoryEntity> categories,
    Map<String, dynamic> json,
  ) {
    return DashboardSummaryEntity(
      userName: userName,
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

  Future<DashboardSummaryEntity> _localSummary(
    String userName,
    List<CategoryEntity> categories,
    Map<String, dynamic> lastServerSummary,
  ) async {
    final movementRepository = _movements;
    final recurringRepository = _recurring;
    if (movementRepository == null || recurringRepository == null) {
      return _serverSummary(userName, categories, lastServerSummary);
    }
    final now = DateTime.now();
    final movements = (await movementRepository.getMovements())
        .where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        )
        .toList();
    final income = movements
        .where((item) => item.type == MovementType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseMovements = movements
        .where((item) => item.type == MovementType.expense)
        .toList();
    final expense = expenseMovements.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totals = <String, double>{};
    for (final movement in expenseMovements) {
      for (final category in movement.categories) {
        totals[category.id] = (totals[category.id] ?? 0) + movement.amount;
      }
    }
    final ranked = totals.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final top = ranked.take(3).map((entry) {
      final category = categories
          .where((candidate) => candidate.id == entry.key)
          .firstOrNull;
      return TopCategorySpend(
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
    final recurring = await recurringRepository.getRecurringMovements();
    final upcoming = recurring
        .where((item) => item.status == RecurringStatus.active)
        .take(3)
        .map(
          (item) => UpcomingRecurringItem(
            name: item.description,
            amount: item.amount,
            date: item.nextExecutionDate,
          ),
        )
        .toList();
    final budgetTotal =
        (lastServerSummary['presupuestoTotal'] as num?)?.toDouble() ?? 0;
    return DashboardSummaryEntity(
      userName: userName,
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      budgetTotal: budgetTotal,
      budgetAvailable: (budgetTotal - expense).clamp(0, double.infinity),
      financialScore:
          (lastServerSummary['scoreFinanciero'] as num?)?.toInt() ?? 0,
      topCategories: top,
      upcomingRecurring: upcoming,
      alertHighlights:
          (lastServerSummary['alertasDestacadas'] as List<dynamic>? ?? const [])
              .cast<String>(),
    );
  }
}

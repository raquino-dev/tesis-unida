import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';

class ApiBudgetRepository implements BudgetRepository {
  final ApiClient _api;
  final CategoryRepository _categories;
  final Map<String, int> _versions = {};

  ApiBudgetRepository(this._api, this._categories);

  @override
  Future<BudgetEntity> getOverallBudget() async {
    final json = (await _api.get('/resumen-presupuestario')).object;
    return BudgetEntity(
      id: 'overall',
      name: 'Presupuesto general',
      amount: (json['total'] as num).toDouble(),
      spent: (json['gastado'] as num).toDouble(),
    );
  }

  @override
  Future<List<BudgetEntity>> getCategoryBudgets() async {
    final json = (await _api.get('/presupuestos')).object;
    final categories = await _categories.getCategories();
    return (json['datos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>, categories))
        .toList();
  }

  @override
  Future<BudgetEntity> createBudget(BudgetEntity budget) async {
    final response = await _api.post('/presupuestos', body: _body(budget));
    return _fromJson(response.object, budget.categories);
  }

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) async {
    final response = await _api.patch(
      '/presupuestos/${budget.id}',
      body: _body(budget),
      headers: {'If-Match': '"${await _versionFor(budget.id)}"'},
    );
    return _fromJson(response.object, budget.categories);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _api.delete(
      '/presupuestos/$id',
      headers: {'If-Match': '"${await _versionFor(id)}"'},
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    if (_versions[id] case final version?) return version;
    final response = (await _api.get('/presupuestos/$id')).object;
    _versions[id] = (response['version'] as num).toInt();
    return _versions[id]!;
  }

  Map<String, dynamic> _body(BudgetEntity budget) => {
    'ambito': 'privado',
    'grupoFamiliarId': null,
    'nombre': budget.name,
    'monto': budget.amount.round(),
    'periodo': _periodToApi(budget.period),
    'categoriaIds': budget.categories.map((item) => item.id).toList(),
  };

  BudgetEntity _fromJson(
    Map<String, dynamic> json,
    List<CategoryEntity> categories,
  ) {
    final ids = (json['categorias'] as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>)['id'] as String)
        .toSet();
    final mapped = categories.where((item) => ids.contains(item.id)).toList();
    if (mapped.length != ids.length) {
      throw const AppFailure(
        'No se pudieron resolver las categorías del presupuesto.',
        code: 'missing_budget_categories',
      );
    }
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    _versions[id] = version;
    return BudgetEntity(
      id: id,
      name: json['nombre'] as String,
      amount: (json['monto'] as num).toDouble(),
      spent: (json['gastado'] as num).toDouble(),
      period: _periodFromApi(json['periodo'] as String),
      categories: mapped,
      version: version,
    );
  }

  String _periodToApi(BudgetPeriod value) => switch (value) {
    BudgetPeriod.weekly => 'semanal',
    BudgetPeriod.monthly => 'mensual',
    BudgetPeriod.annual => 'anual',
  };

  BudgetPeriod _periodFromApi(String value) => switch (value) {
    'semanal' => BudgetPeriod.weekly,
    'anual' => BudgetPeriod.annual,
    _ => BudgetPeriod.monthly,
  };
}

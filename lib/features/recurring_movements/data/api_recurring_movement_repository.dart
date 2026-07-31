import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../movements/domain/movement_entity.dart';
import '../domain/recurring_movement_entity.dart';
import '../domain/recurring_movement_repository.dart';

class ApiRecurringMovementRepository implements RecurringMovementRepository {
  final ApiClient _api;
  final CategoryRepository _categories;
  final AccountRepository _accounts;
  final Map<String, int> _versions = {};

  ApiRecurringMovementRepository(this._api, this._categories, this._accounts);

  @override
  Future<List<RecurringMovementEntity>> getRecurringMovements() async {
    final response = (await _api.get('/movimientos-recurrentes')).object;
    final categories = await _categories.getCategories();
    final accounts = await _accounts.getAccounts();
    return (response['datos'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              _fromJson(item as Map<String, dynamic>, categories, accounts),
        )
        .toList();
  }

  @override
  Future<RecurringMovementEntity> createRecurringMovement(
    RecurringMovementEntity recurring,
  ) async {
    final response = await _api.post(
      '/movimientos-recurrentes',
      body: _body(recurring),
    );
    return _fromJson(response.object, recurring.categories, [
      recurring.account,
    ]);
  }

  @override
  Future<RecurringMovementEntity> updateRecurringMovement(
    RecurringMovementEntity recurring,
  ) async {
    final response = await _api.patch(
      '/movimientos-recurrentes/${recurring.id}',
      body: _body(recurring),
      headers: {'If-Match': '"${await _versionFor(recurring.id)}"'},
    );
    return _fromJson(response.object, recurring.categories, [
      recurring.account,
    ]);
  }

  @override
  Future<RecurringMovementEntity> setStatus(
    RecurringMovementEntity recurring,
    RecurringStatus status,
  ) async {
    final response = await _api.patch(
      '/movimientos-recurrentes/${recurring.id}',
      body: {'estado': _statusToApi(status)},
      headers: {'If-Match': '"${await _versionFor(recurring.id)}"'},
    );
    return _fromJson(response.object, recurring.categories, [
      recurring.account,
    ]);
  }

  @override
  Future<void> deleteRecurringMovement(String id) async {
    await _api.delete(
      '/movimientos-recurrentes/$id',
      headers: {'If-Match': '"${await _versionFor(id)}"'},
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    if (_versions[id] case final version?) return version;
    final response = (await _api.get('/movimientos-recurrentes/$id')).object;
    _versions[id] = (response['version'] as num).toInt();
    return _versions[id]!;
  }

  Map<String, dynamic> _body(RecurringMovementEntity recurring) => {
    'tipo': recurring.type == MovementType.income ? 'ingreso' : 'gasto',
    'monto': recurring.amount.round(),
    'categoriaIds': recurring.categories.map((item) => item.id).toList(),
    'cuentaId': recurring.account.id,
    'descripcion': recurring.description,
    'fechaInicio': _date(recurring.startDate),
    'fechaFin': recurring.endDate == null ? null : _date(recurring.endDate!),
    'frecuencia': _frequencyToApi(recurring.frequency),
    'cantidadOcurrencias': recurring.totalOccurrences,
  };

  RecurringMovementEntity _fromJson(
    Map<String, dynamic> json,
    List<CategoryEntity> categories,
    List<AccountEntity> accounts,
  ) {
    final accountId = (json['cuenta'] as Map<String, dynamic>)['id'] as String;
    final account = accounts.where((item) => item.id == accountId).firstOrNull;
    final categoryIds = (json['categorias'] as List<dynamic>)
        .map((item) => (item as Map<String, dynamic>)['id'] as String)
        .toSet();
    final mappedCategories = categories
        .where((item) => categoryIds.contains(item.id))
        .toList();
    if (account == null || mappedCategories.length != categoryIds.length) {
      throw const AppFailure(
        'No se pudieron resolver la cuenta o las categorías de la recurrencia.',
        code: 'missing_recurring_relations',
      );
    }
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    _versions[id] = version;
    return RecurringMovementEntity(
      id: id,
      type: json['tipo'] == 'ingreso'
          ? MovementType.income
          : MovementType.expense,
      amount: (json['monto'] as num).toDouble(),
      categories: mappedCategories,
      account: account,
      description: json['descripcion'] as String,
      startDate: DateTime.parse(json['fechaInicio'] as String),
      endDate: json['fechaFin'] == null
          ? null
          : DateTime.parse(json['fechaFin'] as String),
      frequency: _frequencyFromApi(json['frecuencia'] as String),
      totalOccurrences: (json['cantidadOcurrencias'] as num?)?.toInt(),
      completedOccurrences: (json['ocurrenciasCompletadas'] as num).toInt(),
      nextExecutionDate: DateTime.parse(json['proximaEjecucion'] as String),
      status: _statusFromApi(json['estado'] as String),
      version: version,
    );
  }

  String _frequencyToApi(RecurrenceFrequency value) => switch (value) {
    RecurrenceFrequency.daily => 'diaria',
    RecurrenceFrequency.weekly => 'semanal',
    RecurrenceFrequency.biweekly => 'quincenal',
    RecurrenceFrequency.monthly => 'mensual',
    RecurrenceFrequency.yearly => 'anual',
  };

  RecurrenceFrequency _frequencyFromApi(String value) => switch (value) {
    'diaria' => RecurrenceFrequency.daily,
    'semanal' => RecurrenceFrequency.weekly,
    'quincenal' => RecurrenceFrequency.biweekly,
    'anual' => RecurrenceFrequency.yearly,
    _ => RecurrenceFrequency.monthly,
  };

  String _statusToApi(RecurringStatus value) => switch (value) {
    RecurringStatus.active => 'activa',
    RecurringStatus.paused => 'pausada',
    RecurringStatus.finished => 'finalizada',
  };

  RecurringStatus _statusFromApi(String value) => switch (value) {
    'pausada' => RecurringStatus.paused,
    'finalizada' => RecurringStatus.finished,
    _ => RecurringStatus.active,
  };

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

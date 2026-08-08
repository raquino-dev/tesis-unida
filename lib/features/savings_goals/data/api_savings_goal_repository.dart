import 'dart:math';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../domain/savings_goal_entity.dart';
import '../domain/savings_goal_repository.dart';

class ApiSavingsGoalRepository implements SavingsGoalRepository {
  final ApiClient _api;
  final Map<String, int> _versions = {};

  ApiSavingsGoalRepository(this._api);

  @override
  Future<List<SavingsGoalEntity>> getGoals() async {
    final json = (await _api.get('/metas-ahorro')).object;
    return (json['datos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavingsGoalEntity> createGoal(SavingsGoalEntity goal) async {
    if (goal.accountId == null) {
      throw const AppFailure(
        'Seleccioná la cuenta donde se guardará la meta.',
        code: 'goal_account_required',
      );
    }
    final response = await _api.post(
      '/metas-ahorro',
      body: {
        'ambito': goal.scope == SavingsGoalScope.family
            ? 'familiar'
            : 'privado',
        'grupoFamiliarId': goal.familyGroupId,
        'nombre': goal.name,
        'montoObjetivo': goal.targetAmount.round(),
        'fechaObjetivo': _date(goal.targetDate),
        'cuentaId': goal.accountId,
      },
    );
    return _fromJson(response.object);
  }

  @override
  Future<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal) async {
    final response = await _api.patch(
      '/metas-ahorro/${goal.id}',
      body: {
        'nombre': goal.name,
        'montoObjetivo': goal.targetAmount.round(),
        'fechaObjetivo': _date(goal.targetDate),
      },
      headers: {'If-Match': '"${await _versionFor(goal.id)}"'},
    );
    return _fromJson(response.object);
  }

  @override
  Future<SavingsGoalEntity> contribute(
    String id,
    double amount, {
    required String accountId,
  }) async {
    await _api.post(
      '/metas-ahorro/$id/aportes',
      headers: {'Idempotency-Key': _idempotencyKey()},
      body: {
        'monto': amount.round(),
        'cuentaOrigenId': accountId,
        'descripcion': 'Aporte desde la aplicación móvil',
      },
    );
    final goal = _fromJson((await _api.get('/metas-ahorro/$id')).object);
    return goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _api.delete(
      '/metas-ahorro/$id',
      headers: {'If-Match': '"${await _versionFor(id)}"'},
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    if (_versions[id] case final version?) return version;
    _fromJson((await _api.get('/metas-ahorro/$id')).object);
    return _versions[id]!;
  }

  SavingsGoalEntity _fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    final account = json['cuenta'] as Map<String, dynamic>;
    _versions[id] = version;
    return SavingsGoalEntity(
      id: id,
      name: json['nombre'] as String,
      targetAmount: (json['montoObjetivo'] as num).toDouble(),
      savedAmount: (json['montoAhorrado'] as num).toDouble(),
      targetDate: DateTime.parse(json['fechaObjetivo'] as String),
      scope: json['ambito'] == 'familiar'
          ? SavingsGoalScope.family
          : SavingsGoalScope.private,
      accountId: account['id'] as String,
      accountName: account['nombre'] as String,
      familyGroupId: json['grupoFamiliarId'] as String?,
      version: version,
    );
  }

  String _idempotencyKey() =>
      'goal-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

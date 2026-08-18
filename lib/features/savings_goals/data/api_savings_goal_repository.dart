import 'dart:math';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';
import '../../../core/utils/uuid_v4.dart';
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
    final id = uuidOrNew(goal.id);
    final optimistic = _json(goal, id: id, version: 1);
    final response = await _api.post(
      '/metas-ahorro',
      body: {
        'id': id,
        'ambito': goal.scope == SavingsGoalScope.family
            ? 'familiar'
            : 'privado',
        'grupoFamiliarId': goal.familyGroupId,
        'nombre': goal.name,
        'montoObjetivo': goal.targetAmount.round(),
        'fechaObjetivo': _date(goal.targetDate),
        'cuentaId': goal.accountId,
      },
      offline: goal.scope == SavingsGoalScope.private
          ? OfflineMutation(
              entityType: 'meta_ahorro',
              entityId: id,
              optimisticResponse: optimistic,
              collectionPath: '/metas-ahorro',
              collectionField: 'datos',
            )
          : null,
    );
    return _fromJson(response.object);
  }

  @override
  Future<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal) async {
    final version = await _versionFor(goal.id);
    final response = await _api.patch(
      '/metas-ahorro/${goal.id}',
      body: {
        'nombre': goal.name,
        'montoObjetivo': goal.targetAmount.round(),
        'fechaObjetivo': _date(goal.targetDate),
      },
      headers: {'If-Match': '"$version"'},
      offline: goal.scope == SavingsGoalScope.private
          ? OfflineMutation(
              entityType: 'meta_ahorro',
              entityId: goal.id,
              optimisticResponse: _json(
                goal,
                id: goal.id,
                version: version + 1,
              ),
              collectionPath: '/metas-ahorro',
              collectionField: 'datos',
            )
          : null,
    );
    return _fromJson(response.object);
  }

  @override
  Future<SavingsGoalEntity> contribute(
    String id,
    double amount, {
    required String accountId,
  }) async {
    final current = (await getGoals()).where((item) => item.id == id).firstOrNull;
    if (current == null) {
      throw const AppFailure('No se encontró la meta de ahorro.');
    }
    final optimisticGoal = current.copyWith(
      savedAmount: current.savedAmount + amount,
      version: current.version + 1,
    );
    final response = await _api.post(
      '/metas-ahorro/$id/aportes',
      headers: {'Idempotency-Key': _idempotencyKey()},
      body: {
        'monto': amount.round(),
        'cuentaOrigenId': accountId,
        'descripcion': 'Aporte desde la aplicación móvil',
      },
      offline: current.scope == SavingsGoalScope.private
          ? OfflineMutation(
              entityType: 'aporte_meta',
              entityId: _idempotencyKey(),
              optimisticResponse: _json(
                optimisticGoal,
                id: id,
                version: optimisticGoal.version,
              ),
              collectionPath: '/metas-ahorro',
              collectionField: 'datos',
            )
          : null,
    );
    if (response.statusCode == 202) return optimisticGoal;
    final goal = _fromJson((await _api.get('/metas-ahorro/$id')).object);
    return goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    final current = (await getGoals()).where((item) => item.id == id).firstOrNull;
    final version = await _versionFor(id);
    await _api.delete(
      '/metas-ahorro/$id',
      headers: {'If-Match': '"$version"'},
      offline: current?.scope == SavingsGoalScope.private
          ? OfflineMutation(
              entityType: 'meta_ahorro',
              entityId: id,
              optimisticResponse: const <String, dynamic>{},
              collectionPath: '/metas-ahorro',
              collectionField: 'datos',
            )
          : null,
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

  Map<String, dynamic> _json(
    SavingsGoalEntity goal, {
    required String id,
    required int version,
  }) => {
    'id': id,
    'nombre': goal.name,
    'montoObjetivo': goal.targetAmount.round(),
    'montoAhorrado': goal.savedAmount.round(),
    'fechaObjetivo': _date(goal.targetDate),
    'ambito': goal.scope == SavingsGoalScope.family ? 'familiar' : 'privado',
    'grupoFamiliarId': goal.familyGroupId,
    'cuenta': {
      'id': goal.accountId,
      'nombre': goal.accountName ?? 'Cuenta',
    },
    'version': version,
  };

  String _idempotencyKey() =>
      'goal-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

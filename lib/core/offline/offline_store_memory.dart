import 'offline_models.dart';
import 'offline_store_base.dart';

OfflineStore createOfflineStore() => MemoryOfflineStore();

class MemoryOfflineStore implements OfflineStore {
  final Map<String, Object?> _cache = {};
  final Map<String, OfflineOperation> _operations = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    _cache.clear();
    _operations.clear();
  }

  String _cacheKey(String userKey, String key) => '$userKey::$key';

  @override
  Future<void> cacheResponse(String userKey, String key, Object? value) async {
    _cache[_cacheKey(userKey, key)] = value;
  }

  @override
  Future<Object?> cachedResponse(String userKey, String key) async =>
      _cache[_cacheKey(userKey, key)];

  @override
  Future<void> removeCachedResponse(String userKey, String key) async {
    _cache.remove(_cacheKey(userKey, key));
  }

  @override
  Future<void> enqueue(OfflineOperation operation) async {
    _operations[operation.id] = operation;
  }

  @override
  Future<List<OfflineOperation>> pendingOperations(String userKey) async {
    final values =
        _operations.values
            .where(
              (item) =>
                  item.userKey == userKey &&
                  item.status == OfflineOperationStatus.pending &&
                  (item.nextAttemptAt == null ||
                      !item.nextAttemptAt!.isAfter(DateTime.now().toUtc())),
            )
            .toList()
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return values;
  }

  @override
  Future<List<OfflineOperation>> operationsByStatus(
    String userKey,
    OfflineOperationStatus status,
  ) async =>
      _operations.values
          .where((item) => item.userKey == userKey && item.status == status)
          .toList()
        ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

  @override
  Future<void> markSyncing(String operationId) async {
    _replace(operationId, OfflineOperationStatus.syncing);
  }

  @override
  Future<void> markCompleted(String operationId) async {
    _operations.remove(operationId);
  }

  @override
  Future<void> markFailed(
    String operationId, {
    required String error,
    required bool conflict,
    required bool terminal,
    required int attemptCount,
    DateTime? nextAttemptAt,
  }) async {
    final old = _operations[operationId];
    if (old == null) return;
    _operations[operationId] = OfflineOperation(
      id: old.id,
      userKey: old.userKey,
      method: old.method,
      path: old.path,
      body: old.body,
      headers: old.headers,
      entityType: old.entityType,
      entityId: old.entityId,
      dependsOn: old.dependsOn,
      status: conflict
          ? OfflineOperationStatus.conflict
          : (terminal
                ? OfflineOperationStatus.failed
                : OfflineOperationStatus.pending),
      attemptCount: attemptCount,
      createdAt: old.createdAt,
      nextAttemptAt: nextAttemptAt,
      lastError: error,
    );
  }

  @override
  Future<int> countByStatus(
    String userKey,
    OfflineOperationStatus status,
  ) async => _operations.values
      .where((item) => item.userKey == userKey && item.status == status)
      .length;

  @override
  Future<void> resetOperation(String operationId) async {
    final old = _operations[operationId];
    if (old == null) return;
    _operations[operationId] = OfflineOperation(
      id: old.id,
      userKey: old.userKey,
      method: old.method,
      path: old.path,
      body: old.body,
      headers: old.headers,
      entityType: old.entityType,
      entityId: old.entityId,
      dependsOn: old.dependsOn,
      status: OfflineOperationStatus.pending,
      attemptCount: 0,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<void> removeOperation(String operationId) async {
    _operations.remove(operationId);
  }

  @override
  Future<void> clearUser(String userKey) async {
    _cache.removeWhere((key, _) => key.startsWith('$userKey::'));
    _operations.removeWhere((_, value) => value.userKey == userKey);
  }

  void _replace(String id, OfflineOperationStatus status) {
    final old = _operations[id];
    if (old == null) return;
    _operations[id] = OfflineOperation(
      id: old.id,
      userKey: old.userKey,
      method: old.method,
      path: old.path,
      body: old.body,
      headers: old.headers,
      entityType: old.entityType,
      entityId: old.entityId,
      dependsOn: old.dependsOn,
      status: status,
      attemptCount: old.attemptCount,
      createdAt: old.createdAt,
      nextAttemptAt: old.nextAttemptAt,
      lastError: old.lastError,
    );
  }
}

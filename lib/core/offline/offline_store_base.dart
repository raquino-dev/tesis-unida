import 'offline_models.dart';

abstract interface class OfflineStore {
  Future<void> initialize();
  Future<void> dispose();

  Future<void> cacheResponse(String userKey, String key, Object? value);
  Future<Object?> cachedResponse(String userKey, String key);
  Future<void> removeCachedResponse(String userKey, String key);

  Future<void> enqueue(OfflineOperation operation);
  Future<List<OfflineOperation>> pendingOperations(String userKey);
  Future<List<OfflineOperation>> operationsByStatus(
    String userKey,
    OfflineOperationStatus status,
  );
  Future<void> markSyncing(String operationId);
  Future<void> markCompleted(String operationId);
  Future<void> markFailed(
    String operationId, {
    required String error,
    required bool conflict,
    required bool terminal,
    required int attemptCount,
    DateTime? nextAttemptAt,
  });
  Future<int> countByStatus(String userKey, OfflineOperationStatus status);
  Future<void> resetOperation(String operationId);
  Future<void> removeOperation(String operationId);
  Future<void> clearUser(String userKey);
}

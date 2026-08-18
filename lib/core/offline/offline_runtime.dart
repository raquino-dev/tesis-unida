import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../errors/app_failure.dart';
import '../services/pilot_local_store.dart';
import 'offline_models.dart';
import 'offline_store.dart';
import 'offline_store_base.dart';

typedef OfflineOperationSender =
    Future<void> Function(OfflineOperation operation);
typedef OfflineChangePuller = Future<void> Function(Set<String> forceTypes);

class OfflineRuntime {
  OfflineRuntime._();

  static final OfflineRuntime instance = OfflineRuntime._();

  final OfflineStore _store = createOfflineStore();
  final StreamController<OfflineSyncSnapshot> _controller =
      StreamController<OfflineSyncSnapshot>.broadcast();
  OfflineSyncSnapshot _snapshot = const OfflineSyncSnapshot();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  OfflineOperationSender? _sender;
  OfflineChangePuller? _puller;
  Future<void>? _synchronizing;
  Future<void>? _initializing;
  bool _initialized = false;
  static const _maximumAttempts = 5;

  Stream<OfflineSyncSnapshot> get changes => _controller.stream;
  OfflineSyncSnapshot get snapshot => _snapshot;

  Future<void> initialize() async {
    if (_initialized) return;
    final active = _initializing;
    if (active != null) return active;
    final future = _initialize();
    _initializing = future;
    try {
      await future;
      _initialized = true;
    } finally {
      if (identical(_initializing, future)) _initializing = null;
    }
  }

  Future<void> _initialize() async {
    await _store.initialize();
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    _setSnapshot(online: _hasNetwork(initial));
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final available = _hasNetwork(results);
      _setSnapshot(online: available);
      if (available) unawaited(synchronize());
    });
    await refreshCounts();
  }

  void registerSender(
    OfflineOperationSender sender, {
    OfflineChangePuller? puller,
  }) {
    _sender = sender;
    _puller = puller;
    if (_snapshot.online) unawaited(synchronize());
  }

  Future<void> cache(String path, Object? value) async {
    if (!_initialized) return;
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey == null) return;
    await _store.cacheResponse(userKey, _cacheKey(path), value);
  }

  Future<Object?> cached(String path) async {
    if (!_initialized) return null;
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey == null) return null;
    return _store.cachedResponse(userKey, _cacheKey(path));
  }

  Future<void> enqueue({
    required String method,
    required String path,
    required Object? body,
    required Map<String, String> headers,
    required OfflineMutation mutation,
  }) async {
    if (!_initialized) await initialize();
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey == null) {
      throw const AppFailure(
        'Iniciá sesión con internet antes de utilizar el modo sin conexión.',
        code: 'offline_session_required',
      );
    }
    final operationId = _randomId();
    final safeHeaders = <String, String>{
      ...headers,
      if (!headers.keys.any((key) => key.toLowerCase() == 'idempotency-key'))
        'Idempotency-Key': 'offline-$operationId',
    };
    await _store.enqueue(
      OfflineOperation(
        id: operationId,
        userKey: userKey,
        method: method,
        path: path,
        body: body,
        headers: safeHeaders,
        entityType: mutation.entityType,
        entityId: mutation.entityId,
        dependsOn: mutation.dependsOn,
        status: OfflineOperationStatus.pending,
        attemptCount: 0,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await _applyOptimisticMutation(userKey, method, mutation);
    _setSnapshot(online: false);
    await refreshCounts();
  }

  Future<void> _applyOptimisticMutation(
    String userKey,
    String method,
    OfflineMutation mutation,
  ) async {
    final path = mutation.collectionPath;
    if (path == null) return;
    final key = _cacheKey(path);
    final current = await _store.cachedResponse(userKey, key);
    if (current is! Map<String, dynamic>) return;
    final rawItems = current[mutation.collectionField];
    if (rawItems is! List<dynamic>) return;
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final index = items.indexWhere((item) => item['id'] == mutation.entityId);
    if (method == 'DELETE') {
      if (index >= 0) items.removeAt(index);
    } else if (mutation.optimisticResponse is Map<String, dynamic>) {
      final replacement = Map<String, dynamic>.from(
        mutation.optimisticResponse as Map<String, dynamic>,
      );
      if (index >= 0) {
        items[index] = replacement;
      } else {
        items.insert(0, replacement);
      }
    }
    current[mutation.collectionField] = items;
    await _store.cacheResponse(userKey, key, current);
  }

  Future<void> synchronize() {
    final active = _synchronizing;
    if (active != null) return active;
    final future = _runSynchronization();
    _synchronizing = future;
    return future.whenComplete(() {
      if (identical(_synchronizing, future)) _synchronizing = null;
    });
  }

  Future<void> _runSynchronization() async {
    if (!_initialized) return;
    final sender = _sender;
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (sender == null || userKey == null || !_snapshot.online) return;
    _setSnapshot(syncing: true, clearError: true);
    final operations = await _store.pendingOperations(userKey);
    for (final operation in operations) {
      try {
        await _store.markSyncing(operation.id);
        await sender(operation);
        await _store.markCompleted(operation.id);
      } on AppFailure catch (failure) {
        final conflict = _isConflict(failure.code);
        final attempts = operation.attemptCount + 1;
        await _store.markFailed(
          operation.id,
          error: failure.message,
          conflict: conflict,
          terminal: !conflict && attempts >= _maximumAttempts,
          attemptCount: attempts,
          nextAttemptAt: conflict
              ? null
              : DateTime.now().toUtc().add(_backoff(attempts)),
        );
        if (!conflict && failure.code == 'network_error') {
          _setSnapshot(online: false, lastError: failure.message);
          break;
        }
      } catch (_) {
        final attempts = operation.attemptCount + 1;
        await _store.markFailed(
          operation.id,
          error: 'No se pudo sincronizar la operación.',
          conflict: false,
          terminal: attempts >= _maximumAttempts,
          attemptCount: attempts,
          nextAttemptAt: DateTime.now().toUtc().add(_backoff(attempts)),
        );
        break;
      }
    }
    if (_snapshot.online) {
      try {
        await _puller?.call(const {});
      } catch (_) {
        // El push ya fue confirmado. El pull se reintentará en otro ciclo.
      }
    }
    await refreshCounts();
    _setSnapshot(
      syncing: false,
      lastSynchronizedAt: _snapshot.online ? DateTime.now() : null,
    );
  }

  Future<void> refreshCounts() async {
    if (!_initialized) return;
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey == null) {
      _setSnapshot(pending: 0, conflicts: 0, failed: 0);
      return;
    }
    final values = await Future.wait([
      _store.countByStatus(userKey, OfflineOperationStatus.pending),
      _store.countByStatus(userKey, OfflineOperationStatus.conflict),
      _store.countByStatus(userKey, OfflineOperationStatus.failed),
    ]);
    _setSnapshot(pending: values[0], conflicts: values[1], failed: values[2]);
  }

  Future<bool> hasPendingOperations() async {
    await refreshCounts();
    return _snapshot.pending > 0 || _snapshot.conflicts > 0;
  }

  Future<List<OfflineOperation>> synchronizationIssues() async {
    if (!_initialized) return const [];
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey == null) return const [];
    final values = await Future.wait([
      _store.operationsByStatus(userKey, OfflineOperationStatus.conflict),
      _store.operationsByStatus(userKey, OfflineOperationStatus.failed),
    ]);
    return [...values[0], ...values[1]];
  }

  Future<void> retryFailedOperations() async {
    final issues = await synchronizationIssues();
    for (final operation in issues.where(
      (item) => item.status == OfflineOperationStatus.failed,
    )) {
      await _store.resetOperation(operation.id);
    }
    await refreshCounts();
    await synchronize();
  }

  Future<void> discardOperation(OfflineOperation operation) async {
    await _store.removeOperation(operation.id);
    await refreshCounts();
    if (_snapshot.online) await _puller?.call({operation.entityType});
  }

  Future<void> clearCurrentUser() async {
    final userKey = await PilotLocalStore.currentUserStorageKey();
    if (userKey != null) await _store.clearUser(userKey);
    await refreshCounts();
  }

  void markNetworkRequestSucceeded() {
    _setSnapshot(online: true, clearError: true);
  }

  void markNetworkRequestFailed(String message) {
    _setSnapshot(online: false, lastError: message);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _store.dispose();
    await _controller.close();
  }

  void _setSnapshot({
    bool? online,
    bool? syncing,
    int? pending,
    int? conflicts,
    int? failed,
    DateTime? lastSynchronizedAt,
    String? lastError,
    bool clearError = false,
  }) {
    _snapshot = _snapshot.copyWith(
      online: online,
      syncing: syncing,
      pending: pending,
      conflicts: conflicts,
      failed: failed,
      lastSynchronizedAt: lastSynchronizedAt,
      lastError: lastError,
      clearError: clearError,
    );
    if (!_controller.isClosed) _controller.add(_snapshot);
  }

  bool _hasNetwork(List<ConnectivityResult> values) =>
      values.any((value) => value != ConnectivityResult.none);

  bool _isConflict(String? code) =>
      code == 'http_409' ||
      code == 'http_412' ||
      code == 'etag_desactualizado' ||
      code == 'conflicto_sincronizacion';

  Duration _backoff(int attempt) {
    final seconds = min(300, 1 << min(attempt, 8));
    return Duration(seconds: seconds);
  }

  String _cacheKey(String path) => path.trim();

  String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

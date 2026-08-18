import 'dart:convert';

enum OfflineOperationStatus { pending, syncing, conflict, failed }

class OfflineOperation {
  const OfflineOperation({
    required this.id,
    required this.userKey,
    required this.method,
    required this.path,
    required this.body,
    required this.headers,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.dependsOn,
    this.nextAttemptAt,
    this.lastError,
  });

  final String id;
  final String userKey;
  final String method;
  final String path;
  final Object? body;
  final Map<String, String> headers;
  final String entityType;
  final String entityId;
  final String? dependsOn;
  final OfflineOperationStatus status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? nextAttemptAt;
  final String? lastError;

  String get bodyJson => jsonEncode(body);
  String get headersJson => jsonEncode(headers);
}

class OfflineSyncSnapshot {
  const OfflineSyncSnapshot({
    this.online = true,
    this.syncing = false,
    this.pending = 0,
    this.conflicts = 0,
    this.failed = 0,
    this.lastSynchronizedAt,
    this.lastError,
  });

  final bool online;
  final bool syncing;
  final int pending;
  final int conflicts;
  final int failed;
  final DateTime? lastSynchronizedAt;
  final String? lastError;

  OfflineSyncSnapshot copyWith({
    bool? online,
    bool? syncing,
    int? pending,
    int? conflicts,
    int? failed,
    DateTime? lastSynchronizedAt,
    String? lastError,
    bool clearError = false,
  }) => OfflineSyncSnapshot(
    online: online ?? this.online,
    syncing: syncing ?? this.syncing,
    pending: pending ?? this.pending,
    conflicts: conflicts ?? this.conflicts,
    failed: failed ?? this.failed,
    lastSynchronizedAt: lastSynchronizedAt ?? this.lastSynchronizedAt,
    lastError: clearError ? null : (lastError ?? this.lastError),
  );
}

class OfflineMutation {
  const OfflineMutation({
    required this.entityType,
    required this.entityId,
    required this.optimisticResponse,
    this.collectionPath,
    this.collectionField = 'elementos',
    this.dependsOn,
  });

  final String entityType;
  final String entityId;
  final Object optimisticResponse;
  final String? collectionPath;
  final String collectionField;
  final String? dependsOn;
}

import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'offline_models.dart';
import 'offline_store_base.dart';

OfflineStore createOfflineStore() => NativeOfflineStore();

class NativeOfflineStore implements OfflineStore {
  static const _databaseKeyName = 'offline.database.key.v1';
  static const _secureStorage = FlutterSecureStorage();

  Database? _database;

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('La base offline todavía no fue inicializada.');
    }
    return database;
  }

  @override
  Future<void> initialize() async {
    if (_database != null) return;
    final directory = await getApplicationSupportDirectory();
    final key = await _readOrCreateEncryptionKey();
    final database = sqlite3.open(
      p.join(directory.path, 'finanzas_offline.db'),
    );
    database.execute("PRAGMA key = '${_escape(key)}';");
    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('PRAGMA journal_mode = WAL;');
    database.execute('PRAGMA busy_timeout = 5000;');
    _database = database;
    _migrate(database);
    database.execute(
      "UPDATE offline_operations SET status = 'pending' WHERE status = 'syncing';",
    );
  }

  Future<String> _readOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: _databaseKeyName);
    if (existing != null && existing.length >= 64) return existing;
    final random = Random.secure();
    final value = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _databaseKeyName, value: value);
    return value;
  }

  void _migrate(Database database) {
    final version = database.userVersion;
    if (version < 1) {
      database.execute('BEGIN IMMEDIATE;');
      try {
        database.execute('''
          CREATE TABLE api_cache (
            user_key TEXT NOT NULL,
            cache_key TEXT NOT NULL,
            value_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (user_key, cache_key)
          );
        ''');
        database.execute('''
          CREATE TABLE offline_operations (
            id TEXT PRIMARY KEY,
            user_key TEXT NOT NULL,
            method TEXT NOT NULL,
            path TEXT NOT NULL,
            body_json TEXT NOT NULL,
            headers_json TEXT NOT NULL,
            entity_type TEXT NOT NULL,
            entity_id TEXT NOT NULL,
            depends_on TEXT,
            status TEXT NOT NULL,
            attempt_count INTEGER NOT NULL DEFAULT 0,
            next_attempt_at TEXT,
            last_error TEXT,
            created_at TEXT NOT NULL
          );
        ''');
        database.execute('''
          CREATE INDEX ix_offline_operations_ready
          ON offline_operations(user_key, status, next_attempt_at, created_at);
        ''');
        database.userVersion = 1;
        database.execute('COMMIT;');
      } catch (_) {
        database.execute('ROLLBACK;');
        rethrow;
      }
    }
  }

  @override
  Future<void> dispose() async {
    _database?.close();
    _database = null;
  }

  @override
  Future<void> cacheResponse(String userKey, String key, Object? value) async {
    _db.execute(
      '''
      INSERT INTO api_cache(user_key, cache_key, value_json, updated_at)
      VALUES(?, ?, ?, ?)
      ON CONFLICT(user_key, cache_key) DO UPDATE SET
        value_json = excluded.value_json,
        updated_at = excluded.updated_at;
      ''',
      [
        userKey,
        key,
        jsonEncode(value),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<Object?> cachedResponse(String userKey, String key) async {
    final rows = _db.select(
      'SELECT value_json FROM api_cache WHERE user_key = ? AND cache_key = ?',
      [userKey, key],
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['value_json'] as String);
  }

  @override
  Future<void> removeCachedResponse(String userKey, String key) async {
    _db.execute('DELETE FROM api_cache WHERE user_key = ? AND cache_key = ?', [
      userKey,
      key,
    ]);
  }

  @override
  Future<void> enqueue(OfflineOperation operation) async {
    _db.execute(
      '''
      INSERT OR REPLACE INTO offline_operations(
        id, user_key, method, path, body_json, headers_json, entity_type,
        entity_id, depends_on, status, attempt_count, next_attempt_at,
        last_error, created_at
      ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        operation.id,
        operation.userKey,
        operation.method,
        operation.path,
        operation.bodyJson,
        operation.headersJson,
        operation.entityType,
        operation.entityId,
        operation.dependsOn,
        operation.status.name,
        operation.attemptCount,
        operation.nextAttemptAt?.toUtc().toIso8601String(),
        operation.lastError,
        operation.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  @override
  Future<List<OfflineOperation>> pendingOperations(String userKey) async {
    final rows = _db.select(
      '''
      SELECT * FROM offline_operations
      WHERE user_key = ? AND status = 'pending'
        AND (next_attempt_at IS NULL OR next_attempt_at <= ?)
      ORDER BY created_at ASC;
      ''',
      [userKey, DateTime.now().toUtc().toIso8601String()],
    );
    return rows.map(_operationFromRow).toList(growable: false);
  }

  @override
  Future<List<OfflineOperation>> operationsByStatus(
    String userKey,
    OfflineOperationStatus status,
  ) async => _db
      .select(
        '''
        SELECT * FROM offline_operations
        WHERE user_key = ? AND status = ?
        ORDER BY created_at ASC;
        ''',
        [userKey, status.name],
      )
      .map(_operationFromRow)
      .toList(growable: false);

  @override
  Future<void> markSyncing(String operationId) async {
    _db.execute(
      "UPDATE offline_operations SET status = 'syncing' WHERE id = ?",
      [operationId],
    );
  }

  @override
  Future<void> markCompleted(String operationId) async {
    _db.execute('DELETE FROM offline_operations WHERE id = ?', [operationId]);
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
    _db.execute(
      '''
      UPDATE offline_operations
      SET status = ?, attempt_count = ?, next_attempt_at = ?, last_error = ?
      WHERE id = ?;
      ''',
      [
        conflict ? 'conflict' : (terminal ? 'failed' : 'pending'),
        attemptCount,
        nextAttemptAt?.toUtc().toIso8601String(),
        error,
        operationId,
      ],
    );
  }

  @override
  Future<int> countByStatus(
    String userKey,
    OfflineOperationStatus status,
  ) async {
    final rows = _db.select(
      'SELECT COUNT(*) AS total FROM offline_operations WHERE user_key = ? AND status = ?',
      [userKey, status.name],
    );
    return rows.first['total'] as int;
  }

  @override
  Future<void> resetOperation(String operationId) async {
    _db.execute(
      '''
      UPDATE offline_operations
      SET status = 'pending', attempt_count = 0,
          next_attempt_at = NULL, last_error = NULL
      WHERE id = ?;
      ''',
      [operationId],
    );
  }

  @override
  Future<void> removeOperation(String operationId) async {
    _db.execute('DELETE FROM offline_operations WHERE id = ?', [operationId]);
  }

  @override
  Future<void> clearUser(String userKey) async {
    _db.execute('BEGIN IMMEDIATE;');
    try {
      _db.execute('DELETE FROM api_cache WHERE user_key = ?', [userKey]);
      _db.execute('DELETE FROM offline_operations WHERE user_key = ?', [
        userKey,
      ]);
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  OfflineOperation _operationFromRow(Row row) => OfflineOperation(
    id: row['id'] as String,
    userKey: row['user_key'] as String,
    method: row['method'] as String,
    path: row['path'] as String,
    body: jsonDecode(row['body_json'] as String),
    headers: (jsonDecode(row['headers_json'] as String) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value.toString())),
    entityType: row['entity_type'] as String,
    entityId: row['entity_id'] as String,
    dependsOn: row['depends_on'] as String?,
    status: OfflineOperationStatus.values.byName(row['status'] as String),
    attemptCount: row['attempt_count'] as int,
    createdAt: DateTime.parse(row['created_at'] as String),
    nextAttemptAt: row['next_attempt_at'] == null
        ? null
        : DateTime.parse(row['next_attempt_at'] as String),
    lastError: row['last_error'] as String?,
  );

  String _escape(String value) => value.replaceAll("'", "''");
}

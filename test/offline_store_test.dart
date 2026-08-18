import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/core/offline/offline_models.dart';
import 'package:finanzas_app/core/offline/offline_store_memory.dart';

void main() {
  group('MemoryOfflineStore', () {
    late MemoryOfflineStore store;

    setUp(() async {
      store = MemoryOfflineStore();
      await store.initialize();
    });

    test('aísla caché y cola por usuario', () async {
      await store.cacheResponse('usuario-a', '/cuentas', {'valor': 'a'});
      await store.cacheResponse('usuario-b', '/cuentas', {'valor': 'b'});
      await store.enqueue(_operation('1', 'usuario-a', 1));
      await store.enqueue(_operation('2', 'usuario-b', 2));

      expect(await store.cachedResponse('usuario-a', '/cuentas'), {
        'valor': 'a',
      });
      expect(await store.cachedResponse('usuario-b', '/cuentas'), {
        'valor': 'b',
      });
      expect(await store.pendingOperations('usuario-a'), hasLength(1));
      expect(await store.pendingOperations('usuario-b'), hasLength(1));
    });

    test('entrega operaciones pendientes en orden de creación', () async {
      await store.enqueue(_operation('posterior', 'usuario', 2));
      await store.enqueue(_operation('anterior', 'usuario', 1));

      final operations = await store.pendingOperations('usuario');

      expect(operations.map((item) => item.id), ['anterior', 'posterior']);
    });

    test('respeta backoff y detiene operaciones terminales', () async {
      await store.enqueue(_operation('backoff', 'usuario', 1));
      await store.markFailed(
        'backoff',
        error: 'sin red',
        conflict: false,
        terminal: false,
        attemptCount: 1,
        nextAttemptAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(await store.pendingOperations('usuario'), isEmpty);

      await store.markFailed(
        'backoff',
        error: 'agotado',
        conflict: false,
        terminal: true,
        attemptCount: 5,
      );
      expect(
        await store.countByStatus('usuario', OfflineOperationStatus.failed),
        1,
      );
    });

    test('limpiar un usuario no elimina información de otro', () async {
      await store.cacheResponse('usuario-a', '/cuentas', const []);
      await store.cacheResponse('usuario-b', '/cuentas', const [1]);
      await store.enqueue(_operation('1', 'usuario-a', 1));
      await store.enqueue(_operation('2', 'usuario-b', 2));

      await store.clearUser('usuario-a');

      expect(await store.cachedResponse('usuario-a', '/cuentas'), isNull);
      expect(await store.pendingOperations('usuario-a'), isEmpty);
      expect(await store.cachedResponse('usuario-b', '/cuentas'), [1]);
      expect(await store.pendingOperations('usuario-b'), hasLength(1));
    });
  });
}

OfflineOperation _operation(String id, String user, int second) =>
    OfflineOperation(
      id: id,
      userKey: user,
      method: 'POST',
      path: '/cuentas',
      body: {'id': id},
      headers: {'Idempotency-Key': id},
      entityType: 'cuenta',
      entityId: id,
      status: OfflineOperationStatus.pending,
      attemptCount: 0,
      createdAt: DateTime.utc(2026, 1, 1, 0, 0, second),
    );

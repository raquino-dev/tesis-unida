import 'package:finanzas_app/core/errors/app_failure.dart';
import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PilotLocalStore.resetMemoryForTesting();
    await PilotLocalStore.initialize();
  });

  test('una sesión recordada sobrevive a un nuevo proceso', () async {
    await PilotLocalStore.saveApiSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      sessionId: 'session',
      rememberSession: true,
    );

    PilotLocalStore.resetMemoryForTesting();
    await PilotLocalStore.initialize();

    expect(PilotLocalStore.hasSession, isTrue);
    expect(PilotLocalStore.remembersSession, isTrue);
  });

  test('una sesión no recordada termina al cerrar el proceso', () async {
    await PilotLocalStore.saveApiSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      sessionId: 'session',
      rememberSession: false,
    );

    expect(PilotLocalStore.hasSession, isTrue);
    expect(PilotLocalStore.remembersSession, isFalse);

    PilotLocalStore.resetMemoryForTesting();
    await PilotLocalStore.initialize();

    expect(PilotLocalStore.hasSession, isFalse);
  });

  test('intenta restaurar online aunque venció la ventana offline', () async {
    await PilotLocalStore.saveApiSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      sessionId: 'session',
      rememberSession: true,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'pilot.auth.last_online',
      DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 8))
          .toIso8601String(),
    );
    PilotLocalStore.resetMemoryForTesting();
    await PilotLocalStore.initialize();

    expect(PilotLocalStore.offlineSessionValid, isFalse);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(sessionRestorationStatusProvider),
      SessionRestorationStatus.restoring,
    );
    expect(container.read(currentUserProvider), isNull);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(container.read(currentUserProvider), isNotNull);
    expect(
      container.read(sessionRestorationStatusProvider),
      SessionRestorationStatus.complete,
    );
  });

  test(
    'un fallo transitorio conserva la sesión y permite reintentar',
    () async {
      await PilotLocalStore.saveApiSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        sessionId: 'session',
        rememberSession: true,
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _UnavailableAuthRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(currentUserProvider);
      await Future<void>.delayed(Duration.zero);

      expect(PilotLocalStore.hasSession, isTrue);
      expect(
        container.read(sessionRestorationStatusProvider),
        SessionRestorationStatus.unavailable,
      );
    },
  );
}

class _UnavailableAuthRepository implements AuthRepository {
  @override
  Future<UserEntity> currentUser() =>
      Future.error(const AppFailure('Sin conexión.', code: 'network_error'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

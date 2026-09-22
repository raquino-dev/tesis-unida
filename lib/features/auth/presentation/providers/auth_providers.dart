import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../family/presentation/family_providers.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/user_alias_policy.dart';
import '../../../security/presentation/security_providers.dart';
import '../../../notifications/presentation/notification_providers.dart';
import '../../../../core/services/pilot_local_store.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/api_providers.dart';
import '../../../../core/offline/offline_runtime.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiAuthRepository(ref.watch(apiClientProvider));
  }
  return MockAuthRepository(ref.watch(familyRepositoryProvider));
});

enum SessionRestorationStatus { restoring, unavailable, complete }

final sessionRestorationStatusProvider =
    StateProvider<SessionRestorationStatus>((ref) {
      return PilotLocalStore.hasSession
          ? SessionRestorationStatus.restoring
          : SessionRestorationStatus.complete;
    });

/// Usuario actual mock. Null cuando no hay sesión iniciada.
class CurrentUserNotifier extends StateNotifier<UserEntity?> {
  final AuthRepository _repository;
  final Ref ref;
  CurrentUserNotifier(this._repository, this.ref) : super(null) {
    if (PilotLocalStore.hasSession) unawaited(restoreSession());
  }

  Future<void> restoreSession() async {
    ref.read(sessionRestorationStatusProvider.notifier).state =
        SessionRestorationStatus.restoring;
    try {
      state = await _repository.currentUser();
      ref.read(sessionRestorationStatusProvider.notifier).state =
          SessionRestorationStatus.complete;
    } on AppFailure catch (failure) {
      if (_invalidSession(failure.code)) {
        await ref.read(pushNotificationServiceProvider).revokeForLogout();
        await PilotLocalStore.clearSession();
        ref.read(sessionRestorationStatusProvider.notifier).state =
            SessionRestorationStatus.complete;
      } else {
        ref.read(sessionRestorationStatusProvider.notifier).state =
            SessionRestorationStatus.unavailable;
      }
      state = null;
    } catch (_) {
      state = null;
      ref.read(sessionRestorationStatusProvider.notifier).state =
          SessionRestorationStatus.unavailable;
    }
  }

  bool _invalidSession(String? code) =>
      code == 'http_401' ||
      code == 'http_403' ||
      code == 'no_autorizado' ||
      code == 'sesion_invalida' ||
      code == 'sesion_revocada' ||
      code == 'refresh_token_invalido' ||
      code == 'usuario_inactivo';

  void setUser(UserEntity user) {
    state = user;
    ref.read(sessionRestorationStatusProvider.notifier).state =
        SessionRestorationStatus.complete;
  }

  Future<UserEntity> updateProfile({
    required String name,
    required String alias,
  }) async {
    final current = state;
    if (current == null) {
      throw const AppFailure(
        'No encontramos una sesión activa.',
        code: 'sesion_invalida',
      );
    }
    final aliasError = UserAliasPolicy.validate(alias);
    if (aliasError != null) {
      throw AppFailure(aliasError, code: 'alias_invalido');
    }
    final updated = await _repository.updateProfile(
      current: current,
      name: name,
      alias: UserAliasPolicy.normalize(alias),
    );
    state = updated;
    return updated;
  }

  Future<void> logout() async {
    await OfflineRuntime.instance.clearCurrentUser();
    await ref.read(pushNotificationServiceProvider).revokeForLogout();
    await _repository.logout();
    await ref.read(securityRepositoryProvider).clearSession();
    await PilotLocalStore.clearSession();
    state = null;
    ref.read(sessionRestorationStatusProvider.notifier).state =
        SessionRestorationStatus.complete;
  }

  Future<void> discardRememberedSession() async {
    await OfflineRuntime.instance.clearCurrentUser();
    await ref.read(pushNotificationServiceProvider).revokeForLogout();
    await PilotLocalStore.clearSession();
    state = null;
    ref.read(sessionRestorationStatusProvider.notifier).state =
        SessionRestorationStatus.complete;
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserEntity?>((ref) {
      return CurrentUserNotifier(ref.watch(authRepositoryProvider), ref);
    });

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(currentUserProvider) != null,
);

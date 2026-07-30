import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';
import '../../../security/domain/security_entity.dart';
import '../../../security/presentation/security_providers.dart';
import '../../../../core/services/pilot_local_store.dart';

class LoginViewModel extends StateNotifier<ViewState<UserEntity>> {
  final Ref _ref;
  LoginViewModel(this._ref) : super(const ViewState.empty());

  Future<void> login({
    required String email,
    required String password,
    required bool rememberSession,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      state = const ViewState.error(
        'Completá tu correo y contraseña para continuar.',
      );
      return;
    }
    state = const ViewState.loading();
    try {
      final repository = _ref.read(authRepositoryProvider);
      final user = await repository.login(email: email, password: password);
      _ref.read(currentUserProvider.notifier).setUser(user);
      final session = await _ref
          .read(securityRepositoryProvider)
          .createSession(trustedDevice: rememberSession);
      await PilotLocalStore.saveSession(session.refreshToken);
      await PilotLocalStore.recordMetric(
        'login_completed',
        data: {'trustedDevice': rememberSession},
      );
      _ref.invalidate(securityEventsProvider);
      state = ViewState.success(user);
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
    } catch (_) {
      await _ref
          .read(securityRepositoryProvider)
          .recordEvent(
            SecurityEventType.failedLogin,
            'Intento fallido de inicio de sesión',
            successful: false,
          );
      _ref.invalidate(securityEventsProvider);
      state = const ViewState.error(
        'No pudimos iniciar sesión. Intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, ViewState<UserEntity>>(
      (ref) => LoginViewModel(ref),
    );

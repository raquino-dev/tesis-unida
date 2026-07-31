import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_providers.dart';
import '../../../security/presentation/security_providers.dart';
import '../../../../core/services/pilot_local_store.dart';
import '../../../../core/config/app_environment.dart';

class RegisterViewModel extends StateNotifier<ViewState<UserEntity>> {
  final Ref _ref;
  RegisterViewModel(this._ref) : super(const ViewState.empty());

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required bool acceptsTerms,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      state = const ViewState.error(
        'Completá todos los campos para continuar.',
      );
      return;
    }
    if (!email.contains('@')) {
      state = const ViewState.error('Ingresá un correo electrónico válido.');
      return;
    }
    if (password != confirmPassword) {
      state = const ViewState.error('Las contraseñas no coinciden.');
      return;
    }
    if (!acceptsTerms) {
      state = const ViewState.error(
        'Debés aceptar los términos y la política de privacidad.',
      );
      return;
    }
    state = const ViewState.loading();
    try {
      final repository = _ref.read(authRepositoryProvider);
      final user = await repository.register(
        name: name,
        email: email,
        password: password,
        acceptsTerms: acceptsTerms,
      );
      _ref.read(currentUserProvider.notifier).setUser(user);
      if (!AppEnvironment.useApi) {
        final session = await _ref
            .read(securityRepositoryProvider)
            .createSession(trustedDevice: true);
        await PilotLocalStore.saveSession(session.refreshToken);
      }
      await PilotLocalStore.recordMetric('registration_completed');
      _ref.invalidate(securityEventsProvider);
      state = ViewState.success(user);
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos crear tu cuenta. Intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();
}

final registerViewModelProvider =
    StateNotifierProvider.autoDispose<RegisterViewModel, ViewState<UserEntity>>(
      (ref) => RegisterViewModel(ref),
    );

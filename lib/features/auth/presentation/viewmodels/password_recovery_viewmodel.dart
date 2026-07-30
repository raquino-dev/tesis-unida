import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../providers/auth_providers.dart';

class PasswordRecoveryViewModel extends StateNotifier<ViewState<String>> {
  final Ref _ref;
  PasswordRecoveryViewModel(this._ref) : super(const ViewState.empty());

  Future<void> sendRecovery(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      state = const ViewState.error('Ingresá un correo electrónico válido.');
      return;
    }
    state = const ViewState.loading();
    try {
      await _ref
          .read(authRepositoryProvider)
          .sendPasswordRecovery(email: email);
      state = ViewState.success(email);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos enviar el correo. Intentá nuevamente.',
      );
    }
  }
}

final passwordRecoveryViewModelProvider =
    StateNotifierProvider.autoDispose<
      PasswordRecoveryViewModel,
      ViewState<String>
    >((ref) => PasswordRecoveryViewModel(ref));

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../providers/auth_providers.dart';

class DeleteAccountViewModel extends StateNotifier<ViewState<bool>> {
  final Ref _ref;
  DeleteAccountViewModel(this._ref) : super(const ViewState.empty());

  Future<void> deleteAccount(String password) async {
    if (password.isEmpty) {
      state = const ViewState.error('Ingresá tu contraseña para confirmar.');
      return;
    }
    state = const ViewState.loading();
    try {
      await _ref.read(authRepositoryProvider).deleteAccount(password: password);
      await _ref.read(currentUserProvider.notifier).logout();
      state = const ViewState.success(true);
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos eliminar tu cuenta. Intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();
}

final deleteAccountViewModelProvider =
    StateNotifierProvider.autoDispose<DeleteAccountViewModel, ViewState<bool>>(
      (ref) => DeleteAccountViewModel(ref),
    );

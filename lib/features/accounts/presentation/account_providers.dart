import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_account_repository.dart';
import '../domain/account_entity.dart';
import '../domain/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => MockAccountRepository(),
);

class AccountListViewModel
    extends StateNotifier<ViewState<List<AccountEntity>>> {
  final AccountRepository _repository;
  AccountListViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final accounts = await _repository.getAccounts();
      state = accounts.isEmpty
          ? const ViewState.empty()
          : ViewState.success(accounts);
    } catch (e) {
      state = ViewState.error(e.toString());
    }
  }

  Future<void> create(AccountEntity account) async {
    await _repository.createAccount(account);
    await load();
  }

  Future<void> update(AccountEntity account) async {
    await _repository.updateAccount(account);
    await load();
  }

  Future<String?> delete(String id) async {
    try {
      await _repository.deleteAccount(id);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }
}

final accountListViewModelProvider =
    StateNotifierProvider<AccountListViewModel, ViewState<List<AccountEntity>>>(
      (ref) {
        return AccountListViewModel(ref.watch(accountRepositoryProvider));
      },
    );

/// Solo cuentas activas, para selectores en formularios (movimientos, transferencias, tarjetas).
final activeAccountsProvider = Provider<List<AccountEntity>>((ref) {
  final state = ref.watch(accountListViewModelProvider);
  return state.when(
    loading: () => [],
    success: (accounts) => accounts.where((a) => a.isActive).toList(),
    error: (_) => [],
    empty: () => [],
  );
});

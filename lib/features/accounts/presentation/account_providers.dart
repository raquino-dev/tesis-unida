import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/view_state.dart';
import '../data/mock_account_repository.dart';
import '../data/api_account_repository.dart';
import '../domain/account_entity.dart';
import '../domain/account_repository.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiAccountRepository(ref.watch(apiClientProvider));
  }
  return MockAccountRepository();
});

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
      state = ViewState.error(
        appErrorMessage(e, fallback: 'No pudimos cargar tus cuentas.'),
      );
    }
  }

  Future<AccountEntity> create(AccountEntity account) async {
    final created = await _repository.createAccount(account);
    await load();
    return created;
  }

  Future<AccountEntity> update(AccountEntity account) async {
    final updated = await _repository.updateAccount(account);
    await load();
    return updated;
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

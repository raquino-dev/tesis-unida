import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../../accounts/presentation/account_providers.dart';
import '../data/api_transfer_repository.dart';
import '../data/mock_transfer_repository.dart';
import '../domain/transfer_entity.dart';
import '../domain/transfer_repository.dart';

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiTransferRepository(
      ref.watch(apiClientProvider),
      ref.watch(accountRepositoryProvider),
    );
  }
  return MockTransferRepository(ref.watch(accountRepositoryProvider));
});

class TransferViewModel extends StateNotifier<ViewState<TransferEntity>> {
  final Ref _ref;
  TransferViewModel(this._ref) : super(const ViewState.empty());

  Future<void> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    state = const ViewState.loading();
    try {
      final repository = _ref.read(transferRepositoryProvider);
      final transfer = await repository.createTransfer(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount,
        date: date,
        note: note,
      );
      await _ref.read(accountListViewModelProvider.notifier).load();
      state = ViewState.success(transfer);
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos realizar la transferencia. Intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();

  Future<String?> cancel(TransferEntity transfer) async {
    try {
      await _ref.read(transferRepositoryProvider).cancelTransfer(transfer);
      await _ref.read(accountListViewModelProvider.notifier).load();
      _ref.invalidate(transferHistoryProvider);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }
}

final transferViewModelProvider =
    StateNotifierProvider.autoDispose<
      TransferViewModel,
      ViewState<TransferEntity>
    >((ref) => TransferViewModel(ref));

final transferHistoryProvider = FutureProvider<List<TransferEntity>>(
  (ref) => ref.watch(transferRepositoryProvider).getTransfers(),
);

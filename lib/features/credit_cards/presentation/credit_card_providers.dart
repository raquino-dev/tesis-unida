import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../../accounts/presentation/account_providers.dart';
import '../data/api_credit_card_repository.dart';
import '../data/mock_credit_card_repository.dart';
import '../domain/credit_card_entity.dart';
import '../domain/credit_card_repository.dart';

final creditCardRepositoryProvider = Provider<CreditCardRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiCreditCardRepository(
      ref.watch(apiClientProvider),
      ref.watch(accountRepositoryProvider),
    );
  }
  return MockCreditCardRepository(ref.watch(accountRepositoryProvider));
});

class CreditCardListViewModel
    extends StateNotifier<ViewState<List<CreditCardEntity>>> {
  final CreditCardRepository _repository;
  CreditCardListViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final cards = await _repository.getCreditCards();
      state = cards.isEmpty
          ? const ViewState.empty()
          : ViewState.success(cards);
    } catch (e) {
      state = ViewState.error(e.toString());
    }
  }

  Future<String?> create(CreditCardEntity card) async {
    try {
      await _repository.createCreditCard(card);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> update(CreditCardEntity card) async {
    try {
      await _repository.updateCreditCard(card);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<void> delete(String id) async {
    await _repository.deleteCreditCard(id);
    await load();
  }
}

final creditCardListViewModelProvider =
    StateNotifierProvider<
      CreditCardListViewModel,
      ViewState<List<CreditCardEntity>>
    >((ref) {
      return CreditCardListViewModel(ref.watch(creditCardRepositoryProvider));
    });

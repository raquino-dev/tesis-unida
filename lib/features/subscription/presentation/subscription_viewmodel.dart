import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../data/api_subscription_repository.dart';
import '../data/mock_subscription_repository.dart';
import '../domain/subscription_entity.dart';
import '../domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (!AppEnvironment.useApi) return MockSubscriptionRepository();
  final repository = ApiSubscriptionRepository(ref.watch(apiClientProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

class SubscriptionViewModel
    extends StateNotifier<ViewState<SubscriptionEntity>> {
  final SubscriptionRepository _repository;
  SubscriptionViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.getSubscription());
    } catch (_) {
      state = const ViewState.error('No pudimos cargar tu suscripción.');
    }
  }

  Future<void> purchase(PlanId plan, String verificationOtpId) async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(
        await _repository.purchase(plan, verificationOtpId),
      );
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
    }
  }

  Future<void> restore() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.restorePurchase());
    } catch (_) {
      state = const ViewState.error('No pudimos restaurar tu compra.');
    }
  }

  Future<void> cancel() async {
    state = const ViewState.loading();
    try {
      state = ViewState.success(await _repository.cancel());
    } catch (_) {
      state = const ViewState.error('No pudimos cancelar la suscripción.');
    }
  }
}

final subscriptionViewModelProvider =
    StateNotifierProvider<SubscriptionViewModel, ViewState<SubscriptionEntity>>(
      (ref) {
        return SubscriptionViewModel(ref.watch(subscriptionRepositoryProvider));
      },
    );

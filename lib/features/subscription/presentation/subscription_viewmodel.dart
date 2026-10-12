import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../data/api_subscription_repository.dart';
import '../data/mock_subscription_repository.dart';
import '../domain/subscription_entity.dart';
import '../domain/subscription_repository.dart';

class SubscriptionPurchaseOutcome {
  final SubscriptionEntity? subscription;
  final String? errorMessage;

  const SubscriptionPurchaseOutcome.success(this.subscription)
    : errorMessage = null;

  const SubscriptionPurchaseOutcome.failure(this.errorMessage)
    : subscription = null;

  bool get succeeded => subscription != null;
}

class SubscriptionRestoreOutcome {
  final SubscriptionEntity? subscription;
  final String? errorMessage;

  const SubscriptionRestoreOutcome.success(this.subscription)
    : errorMessage = null;

  const SubscriptionRestoreOutcome.failure(this.errorMessage)
    : subscription = null;

  bool get succeeded => subscription != null;
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (!AppEnvironment.useApi) return MockSubscriptionRepository();
  final repository = ApiSubscriptionRepository(ref.watch(apiClientProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

class SubscriptionViewModel
    extends StateNotifier<ViewState<SubscriptionEntity>> {
  final SubscriptionRepository _repository;
  bool _restoreInProgress = false;
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

  Future<SubscriptionPurchaseOutcome> purchase(
    PlanId plan,
    String verificationOtpId,
  ) async {
    state = const ViewState.loading();
    try {
      final subscription = await _repository.purchase(plan, verificationOtpId);
      state = ViewState.success(subscription);
      return SubscriptionPurchaseOutcome.success(subscription);
    } on AppFailure catch (e) {
      state = ViewState.error(e.message);
      return SubscriptionPurchaseOutcome.failure(e.message);
    } catch (error) {
      final message = appErrorMessage(
        error,
        fallback: 'No pudimos procesar la compra. Intentá nuevamente.',
      );
      state = ViewState.error(message);
      return SubscriptionPurchaseOutcome.failure(message);
    }
  }

  Future<SubscriptionRestoreOutcome> restore() async {
    if (_restoreInProgress) {
      return const SubscriptionRestoreOutcome.failure(
        'Ya estamos buscando una compra para restaurar.',
      );
    }
    _restoreInProgress = true;
    try {
      final subscription = await _repository.restorePurchase();
      state = ViewState.success(subscription);
      return SubscriptionRestoreOutcome.success(subscription);
    } on AppFailure catch (error) {
      return SubscriptionRestoreOutcome.failure(error.message);
    } catch (_) {
      return const SubscriptionRestoreOutcome.failure(
        'No pudimos restaurar tu compra.',
      );
    } finally {
      _restoreInProgress = false;
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

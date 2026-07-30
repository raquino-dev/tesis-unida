import 'subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionEntity> getSubscription();
  Future<SubscriptionEntity> purchase(PlanId plan);
  Future<SubscriptionEntity> restorePurchase();
  Future<SubscriptionEntity> cancel();
}

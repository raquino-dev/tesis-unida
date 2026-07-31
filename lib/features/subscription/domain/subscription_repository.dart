import 'subscription_entity.dart';

abstract class SubscriptionRepository {
  Future<SubscriptionEntity> getSubscription();
  Future<SubscriptionEntity> purchase(
    PlanId plan, [
    String verificationOtpId = '00000000-0000-0000-0000-000000000000',
  ]);
  Future<SubscriptionEntity> restorePurchase();
  Future<SubscriptionEntity> cancel();
}

enum SubscriptionStatus { free, active, expired }

enum PlanId { free, premiumMonthly, premiumAnnual }

enum PremiumCapability { ocr, predictions, exports, priorityAlerts }

class SubscriptionPlan {
  final PlanId id;
  final String name;
  final double price;
  final String period;
  final List<String> features;
  final bool highlighted;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    this.highlighted = false,
  });
}

class SubscriptionEntity {
  final SubscriptionStatus status;
  final PlanId currentPlan;
  final String renewalDateLabel;
  final List<SubscriptionPlan> plans;

  const SubscriptionEntity({
    required this.status,
    required this.currentPlan,
    required this.renewalDateLabel,
    required this.plans,
  });

  bool get isPremium =>
      status == SubscriptionStatus.active && currentPlan != PlanId.free;
  bool allows(PremiumCapability capability) => isPremium;
}

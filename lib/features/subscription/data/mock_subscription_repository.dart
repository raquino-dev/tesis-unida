import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../domain/subscription_entity.dart';
import '../domain/subscription_repository.dart';
import '../../../core/services/pilot_local_store.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  late SubscriptionStatus _status = _storedPlan == PlanId.free
      ? SubscriptionStatus.free
      : SubscriptionStatus.active;
  late PlanId _currentPlan = _storedPlan;

  PlanId get _storedPlan {
    switch (PilotLocalStore.subscriptionPlan) {
      case 'premiumMonthly':
        return PlanId.premiumMonthly;
      case 'premiumAnnual':
        return PlanId.premiumAnnual;
      default:
        return PlanId.free;
    }
  }

  static const _plans = [
    SubscriptionPlan(
      id: PlanId.free,
      code: 'gratis',
      productId: '',
      name: 'Free',
      price: 0,
      period: 'Siempre',
      features: [
        'Registro manual de movimientos',
        'Categorías básicas',
        'Reportes simples',
        '3 comprobantes OCR por mes',
        'Alertas básicas',
      ],
    ),
    SubscriptionPlan(
      id: PlanId.premiumMonthly,
      code: 'premium-mensual',
      productId: 'premium_monthly',
      name: 'Premium mensual',
      price: 39000,
      period: 'por mes',
      features: [
        'Escaneo OCR ilimitado',
        'Predicciones avanzadas',
        'Exportación a PDF y Excel',
        'Alertas inteligentes prioritarias',
      ],
      highlighted: true,
    ),
    SubscriptionPlan(
      id: PlanId.premiumAnnual,
      code: 'premium-anual',
      productId: 'premium_yearly',
      name: 'Premium anual',
      price: 390000,
      period: 'por año',
      features: [
        'Todo lo de Premium mensual',
        '2 meses de ahorro',
        'Gestión ampliada de cuentas y grupos',
      ],
    ),
  ];

  @override
  Future<SubscriptionEntity> getSubscription() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return SubscriptionEntity(
      status: _status,
      currentPlan: _currentPlan,
      renewalDateLabel: MockData.renewalDateLabel,
      plans: _plans,
    );
  }

  @override
  Future<SubscriptionEntity> purchase(
    PlanId plan, [
    String verificationOtpId = '00000000-0000-0000-0000-000000000000',
  ]) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (plan == PlanId.free) {
      throw const AppFailure('Seleccioná un plan premium para continuar.');
    }
    _status = SubscriptionStatus.active;
    _currentPlan = plan;
    await PilotLocalStore.saveSubscriptionPlan(plan.name);
    await PilotLocalStore.recordMetric(
      'subscription_activated',
      data: {'plan': plan.name},
    );
    return getSubscription();
  }

  @override
  Future<SubscriptionEntity> restorePurchase() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return getSubscription();
  }

  @override
  Future<SubscriptionEntity> cancel() async {
    await Future.delayed(const Duration(milliseconds: 550));
    _status = SubscriptionStatus.free;
    _currentPlan = PlanId.free;
    await PilotLocalStore.saveSubscriptionPlan(PlanId.free.name);
    await PilotLocalStore.recordMetric('subscription_cancelled');
    return getSubscription();
  }
}

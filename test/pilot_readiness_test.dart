import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/subscription/data/mock_subscription_repository.dart';
import 'package:finanzas_app/features/subscription/domain/subscription_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Preparación de la prueba piloto', () {
    test(
      'el plan aprobado usa precios de 39.000 y 390.000 guaraníes',
      () async {
        final subscription = await MockSubscriptionRepository()
            .getSubscription();
        final monthly = subscription.plans.firstWhere(
          (plan) => plan.id == PlanId.premiumMonthly,
        );
        final annual = subscription.plans.firstWhere(
          (plan) => plan.id == PlanId.premiumAnnual,
        );

        expect(monthly.price, 39000);
        expect(annual.price, 390000);
        expect(
          subscription.plans.first.features,
          contains('3 comprobantes OCR por mes'),
        );
      },
    );

    test(
      'el plan gratuito permite tres usos OCR y luego agota la cuota',
      () async {
        expect(PilotLocalStore.hasFreeOcrQuota, isTrue);
        await PilotLocalStore.registerOcrUse();
        await PilotLocalStore.registerOcrUse();
        await PilotLocalStore.registerOcrUse();

        expect(PilotLocalStore.monthlyOcrCount, 3);
        expect(PilotLocalStore.hasFreeOcrQuota, isFalse);
      },
    );

    test(
      'consentimiento, encuestas y métricas quedan registrados localmente',
      () async {
        await PilotLocalStore.acceptConsent();
        await PilotLocalStore.completePreSurvey();
        await PilotLocalStore.recordMetric('pilot_test', data: {'value': 1});

        expect(PilotLocalStore.consentAccepted, isTrue);
        expect(PilotLocalStore.preSurveyCompleted, isTrue);
        expect(PilotLocalStore.getMetrics().last['name'], 'pilot_test');
      },
    );
  });
}

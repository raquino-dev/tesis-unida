import 'dart:async';

import 'package:finanzas_app/features/subscription/data/google_play_billing_service.dart';
import 'package:finanzas_app/features/subscription/domain/subscription_entity.dart';
import 'package:finanzas_app/features/subscription/domain/subscription_repository.dart';
import 'package:finanzas_app/features/subscription/presentation/subscription_viewmodel.dart';
import 'package:finanzas_app/features/subscription/presentation/subscription_purchase_result_screen.dart';
import 'package:finanzas_app/features/subscription/presentation/subscription_screen.dart';
import 'package:finanzas_app/core/errors/app_failure.dart';
import 'package:finanzas_app/core/utils/view_state.dart';
import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  group('Regresiones de suscripción', () {
    test('el plan gratuito nunca anuncia una fecha de renovación', () {
      const subscription = SubscriptionEntity(
        status: SubscriptionStatus.active,
        currentPlan: PlanId.free,
        renewalDateLabel: '2126-08-08',
        plans: [],
      );

      expect(subscription.isPremium, isFalse);
      expect(subscription.hasRenewalDate, isFalse);
    });

    test('una suscripción cancelada conserva acceso pero ya no renueva', () {
      const subscription = SubscriptionEntity(
        status: SubscriptionStatus.cancelled,
        currentPlan: PlanId.premiumMonthly,
        renewalDateLabel: '2026-10-20',
        plans: [],
      );

      expect(subscription.isPremium, isTrue);
      expect(subscription.hasRenewalDate, isTrue);
      expect(subscription.renews, isFalse);
    });

    test(
      'una excepción de Billing abandona el estado de procesamiento',
      () async {
        final viewModel = SubscriptionViewModel(
          _SubscriptionRepository(
            purchaseError: StateError('billing rejected'),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final outcome = await viewModel.purchase(
          PlanId.premiumMonthly,
          'verification-id',
        );

        expect(outcome.succeeded, isFalse);
        expect(
          outcome.errorMessage,
          'No pudimos procesar la compra. Intentá nuevamente.',
        );
        expect(viewModel.state, isA<ViewError<SubscriptionEntity>>());
        expect(
          (viewModel.state as ViewError<SubscriptionEntity>).message,
          'No pudimos procesar la compra. Intentá nuevamente.',
        );
        viewModel.dispose();
      },
    );

    test('captura un rechazo mientras Google Play inicia la compra', () async {
      final billing = _RejectingBillingClient();
      final service = GooglePlayBillingService(billing: billing);
      final product = ProductDetails(
        id: 'premium_monthly',
        title: 'Premium mensual',
        description: 'Plan mensual',
        price: 'Gs. 39.000',
        rawPrice: 39000,
        currencyCode: 'PYG',
      );

      final purchase = await service.purchase(product);

      expect(purchase.status, PurchaseStatus.error);
      expect(
        () => service.validate(purchase),
        throwsA(
          predicate(
            (error) => error.toString().contains('medio de pago fue rechazado'),
          ),
        ),
      );
      await service.dispose();
      await billing.dispose();
    });

    test('restaura una compra confirmada por Google Play', () async {
      final billing = _RestoringBillingClient();
      final service = GooglePlayBillingService(billing: billing);

      final purchase = await service.restore({
        'premium_monthly',
        'premium_yearly',
      });

      expect(billing.restoreCalls, 1);
      expect(purchase.productID, 'premium_monthly');
      expect(purchase.status, PurchaseStatus.restored);
      expect(() => service.validate(purchase), returnsNormally);

      await service.complete(purchase);
      expect(billing.completedPurchaseIds, ['restored-purchase']);
      await service.dispose();
      await billing.dispose();
    });

    test(
      'conserva el motivo cuando no existe una compra para restaurar',
      () async {
        final viewModel = SubscriptionViewModel(
          _SubscriptionRepository(
            restoreError: const AppFailure(
              'No se encontró una compra para restaurar.',
              code: 'purchase_not_found',
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final outcome = await viewModel.restore();

        expect(outcome.succeeded, isFalse);
        expect(
          outcome.errorMessage,
          'No se encontró una compra para restaurar.',
        );
        expect(viewModel.state, isA<ViewSuccess<SubscriptionEntity>>());
        viewModel.dispose();
      },
    );

    testWidgets('el botón ejecuta la restauración de compra', (tester) async {
      final repository = _SubscriptionRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SubscriptionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restaurar compra'));
      await tester.pumpAndSettle();

      expect(repository.restoreCalls, 1);
      expect(find.text('Plan Free'), findsOneWidget);
      expect(find.text('Tu compra se restauró correctamente.'), findsOneWidget);
    });

    testWidgets('mantiene los planes visibles mientras restaura', (
      tester,
    ) async {
      final pendingRestore = Completer<SubscriptionEntity>();
      final repository = _SubscriptionRepository(
        restoreCompleter: pendingRestore,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SubscriptionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Restaurar compra'));
      await tester.pump();

      expect(repository.restoreCalls, 1);
      expect(find.text('Plan Free'), findsOneWidget);
      expect(find.text('Procesando...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pendingRestore.complete(_SubscriptionRepository.freeSubscription);
      await tester.pumpAndSettle();
    });

    testWidgets('muestra la confirmación visual después del pago', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const SubscriptionPurchaseResultScreen.success(
            subscription: SubscriptionEntity(
              status: SubscriptionStatus.active,
              currentPlan: PlanId.premiumMonthly,
              renewalDateLabel: '2026-10-20',
              startedDateLabel: '2026-09-20',
              paymentMethodLabel: 'Google Play',
              plans: [],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('purchase-success')), findsOneWidget);
      expect(find.text('Finanza Premium mensual'), findsOneWidget);
      expect(find.text('20 de octubre de 2026'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('muestra acciones cuando el pago es rechazado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const SubscriptionPurchaseResultScreen.failure(
            errorMessage: 'El medio de pago fue rechazado.',
          ),
        ),
      );

      expect(find.byKey(const ValueKey('purchase-error')), findsOneWidget);
      expect(find.text('Intentar nuevamente'), findsOneWidget);
      expect(find.text('Cambiar método de pago'), findsOneWidget);
    });
  });
}

class _SubscriptionRepository implements SubscriptionRepository {
  final Object? purchaseError;
  final Object? restoreError;
  final Completer<SubscriptionEntity>? restoreCompleter;
  int restoreCalls = 0;

  _SubscriptionRepository({
    this.purchaseError,
    this.restoreError,
    this.restoreCompleter,
  });

  static const freeSubscription = SubscriptionEntity(
    status: SubscriptionStatus.free,
    currentPlan: PlanId.free,
    renewalDateLabel: '',
    plans: [],
  );

  @override
  Future<SubscriptionEntity> getSubscription() async => freeSubscription;

  @override
  Future<SubscriptionEntity> purchase(
    PlanId plan, [
    String verificationOtpId = '00000000-0000-0000-0000-000000000000',
  ]) async {
    if (purchaseError case final error?) throw error;
    return freeSubscription;
  }

  @override
  Future<SubscriptionEntity> restorePurchase() async {
    restoreCalls++;
    if (restoreError case final error?) throw error;
    if (restoreCompleter case final completer?) return completer.future;
    return freeSubscription;
  }

  @override
  Future<SubscriptionEntity> cancel() async => freeSubscription;
}

class _RejectingBillingClient implements GooglePlayBillingClient {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast(
    sync: true,
  );

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) async {
    _controller.add([
      PurchaseDetails(
          purchaseID: 'rejected-purchase',
          productID: purchaseParam.productDetails.id,
          verificationData: PurchaseVerificationData(
            localVerificationData: '',
            serverVerificationData: '',
            source: 'google_play',
          ),
          transactionDate: null,
          status: PurchaseStatus.error,
        )
        ..error = IAPError(
          source: 'google_play',
          code: 'payment_declined',
          message: 'Payment declined',
        ),
    ]);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: [], notFoundIDs: ids.toList());

  @override
  Future<void> restorePurchases() async {}

  Future<void> dispose() => _controller.close();
}

class _RestoringBillingClient implements GooglePlayBillingClient {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast(
    sync: true,
  );
  final completedPurchaseIds = <String?>[];
  int restoreCalls = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) async => true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchaseIds.add(purchase.purchaseID);
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: [], notFoundIDs: ids.toList());

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    _controller.add([
      PurchaseDetails(
        purchaseID: 'restored-purchase',
        productID: 'premium_monthly',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local-token',
          serverVerificationData: 'server-token',
          source: 'google_play',
        ),
        transactionDate: '1789833600000',
        status: PurchaseStatus.restored,
      )..pendingCompletePurchase = true,
    ]);
  }

  Future<void> dispose() => _controller.close();
}

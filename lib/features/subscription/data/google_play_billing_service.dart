import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/errors/app_failure.dart';

class GooglePlayBillingService {
  final InAppPurchase _billing;
  final StreamController<PurchaseDetails> _purchases =
      StreamController<PurchaseDetails>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  GooglePlayBillingService({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance {
    _subscription = _billing.purchaseStream.listen((items) {
      for (final item in items) {
        _purchases.add(item);
      }
    }, onError: _purchases.addError);
  }

  Future<Map<String, ProductDetails>> queryProducts(Set<String> ids) async {
    if (!await _billing.isAvailable()) {
      throw const AppFailure(
        'Google Play Billing no está disponible en este dispositivo.',
        code: 'billing_unavailable',
      );
    }
    final response = await _billing.queryProductDetails(ids);
    if (response.error != null) {
      throw AppFailure(response.error!.message, code: response.error!.code);
    }
    return {for (final product in response.productDetails) product.id: product};
  }

  Future<PurchaseDetails> purchase(ProductDetails product) async {
    final started = await _billing.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      throw const AppFailure(
        'Google Play no pudo iniciar la compra.',
        code: 'billing_not_started',
      );
    }
    return _waitForPurchase(product.id);
  }

  Future<PurchaseDetails> restore(Set<String> productIds) async {
    await _billing.restorePurchases();
    return _purchases.stream
        .firstWhere(
          (purchase) =>
              productIds.contains(purchase.productID) &&
              purchase.status != PurchaseStatus.pending,
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw const AppFailure(
            'No se encontró una compra para restaurar.',
            code: 'purchase_not_found',
          ),
        );
  }

  Future<PurchaseDetails> _waitForPurchase(String productId) => _purchases
      .stream
      .firstWhere(
        (purchase) =>
            purchase.productID == productId &&
            purchase.status != PurchaseStatus.pending,
      )
      .timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw const AppFailure(
          'La compra continúa pendiente en Google Play.',
          code: 'purchase_pending',
        ),
      );

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _billing.completePurchase(purchase);
    }
  }

  void validate(PurchaseDetails purchase) {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (purchase.verificationData.serverVerificationData.isEmpty) {
          throw const AppFailure(
            'Google Play no devolvió un comprobante verificable.',
            code: 'missing_purchase_token',
          );
        }
        return;
      case PurchaseStatus.canceled:
        throw const AppFailure(
          'La compra fue cancelada.',
          code: 'purchase_cancelled',
        );
      case PurchaseStatus.error:
        throw AppFailure(
          purchase.error?.message ?? 'Google Play rechazó la compra.',
          code: purchase.error?.code ?? 'purchase_error',
        );
      case PurchaseStatus.pending:
        throw const AppFailure(
          'La compra está pendiente de confirmación.',
          code: 'purchase_pending',
        );
    }
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _purchases.close();
  }
}

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/errors/app_failure.dart';

class GooglePlayBillingService {
  static const _purchaseTimeout = Duration(seconds: 45);
  final GooglePlayBillingClient _billing;
  final StreamController<PurchaseDetails> _purchases =
      StreamController<PurchaseDetails>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  GooglePlayBillingService({GooglePlayBillingClient? billing})
    : _billing = billing ?? _InAppPurchaseBillingClient() {
    _subscription = _billing.purchaseStream.listen(
      (items) {
        for (final item in items) {
          _purchases.add(item);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _purchases.addError(_asBillingFailure(error), stackTrace);
      },
    );
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
      throw AppFailure(
        _billingErrorMessage(
          response.error!.code,
          fallback: 'No pudimos consultar los planes disponibles.',
        ),
        code: response.error!.code,
      );
    }
    return {for (final product in response.productDetails) product.id: product};
  }

  Future<PurchaseDetails> purchase(ProductDetails product) async {
    // Nos suscribimos antes de abrir Google Play. Un rechazo puede llegar por
    // el stream antes de que buyNonConsumable termine y un stream broadcast no
    // conserva ese evento para oyentes tardíos.
    final waiter = _createPurchaseWaiter(
      matches: (purchase) => purchase.productID == product.id,
      timeoutMessage:
          'Google Play no confirmó la compra. Revisá el medio de pago e intentá nuevamente.',
      timeoutCode: 'purchase_not_confirmed',
    );
    Future<void> startPurchase() async {
      final started = await _billing.buyNonConsumable(
        PurchaseParam(productDetails: product),
      );
      if (!started) {
        throw const AppFailure(
          'Google Play no pudo iniciar la compra.',
          code: 'billing_not_started',
        );
      }
    }

    try {
      final results = await Future.wait<Object?>([
        startPurchase(),
        waiter.future,
      ], eagerError: true);
      return results[1]! as PurchaseDetails;
    } catch (error) {
      await waiter.cancel();
      throw _asBillingFailure(error);
    }
  }

  Future<PurchaseDetails> restore(Set<String> productIds) async {
    final waiter = _createPurchaseWaiter(
      matches: (purchase) => productIds.contains(purchase.productID),
      timeoutMessage: 'No se encontró una compra para restaurar.',
      timeoutCode: 'purchase_not_found',
    );
    try {
      final results = await Future.wait<Object?>([
        _billing.restorePurchases(),
        waiter.future,
      ], eagerError: true);
      return results[1]! as PurchaseDetails;
    } catch (error) {
      await waiter.cancel();
      throw _asBillingFailure(
        error,
        fallback: 'No pudimos restaurar tu compra.',
      );
    }
  }

  _PurchaseWaiter _createPurchaseWaiter({
    required bool Function(PurchaseDetails purchase) matches,
    required String timeoutMessage,
    required String timeoutCode,
  }) {
    final completer = Completer<PurchaseDetails>();
    late final StreamSubscription<PurchaseDetails> subscription;
    late final Timer timer;

    void finishWithError(Object error, [StackTrace? stackTrace]) {
      if (completer.isCompleted) return;
      timer.cancel();
      unawaited(subscription.cancel());
      completer.completeError(error, stackTrace);
    }

    timer = Timer(
      _purchaseTimeout,
      () => finishWithError(AppFailure(timeoutMessage, code: timeoutCode)),
    );
    subscription = _purchases.stream.listen(
      (purchase) {
        if (!matches(purchase) || purchase.status == PurchaseStatus.pending) {
          return;
        }
        if (completer.isCompleted) return;
        timer.cancel();
        unawaited(subscription.cancel());
        completer.complete(purchase);
      },
      onError: (Object error, StackTrace stackTrace) {
        finishWithError(_asBillingFailure(error), stackTrace);
      },
    );
    return _PurchaseWaiter(completer.future, () async {
      timer.cancel();
      await subscription.cancel();
    });
  }

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
          _billingErrorMessage(
            purchase.error?.code,
            fallback:
                'El medio de pago fue rechazado. Revisá sus datos o utilizá otro.',
          ),
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

  String _billingErrorMessage(String? code, {required String fallback}) {
    final normalized = code?.toLowerCase() ?? '';
    if (normalized.contains('cancel')) return 'La compra fue cancelada.';
    if (normalized.contains('declin') ||
        normalized.contains('reject') ||
        normalized.contains('payment') ||
        normalized.contains('invalid')) {
      return 'El medio de pago fue rechazado. Revisá sus datos o utilizá otro.';
    }
    if (normalized.contains('network') || normalized.contains('service')) {
      return 'No pudimos comunicarnos con Google Play. Intentá nuevamente.';
    }
    if (normalized.contains('unavailable') ||
        normalized.contains('not_found')) {
      return 'El producto no está disponible en este momento.';
    }
    if (normalized.contains('already_owned')) {
      return 'Este plan ya está asociado a tu cuenta.';
    }
    return fallback;
  }

  AppFailure _asBillingFailure(
    Object error, {
    String fallback =
        'No pudimos procesar la compra. Revisá el medio de pago e intentá nuevamente.',
  }) {
    if (error is AppFailure) return error;
    if (error is IAPError) {
      return AppFailure(
        _billingErrorMessage(error.code, fallback: fallback),
        code: error.code,
      );
    }
    if (error is InAppPurchaseException) {
      return AppFailure(
        _billingErrorMessage(error.code, fallback: fallback),
        code: error.code,
      );
    }
    return AppFailure(fallback, code: 'billing_error');
  }
}

class _PurchaseWaiter {
  final Future<PurchaseDetails> future;
  final Future<void> Function() _cancel;

  const _PurchaseWaiter(this.future, this._cancel);

  Future<void> cancel() => _cancel();
}

abstract class GooglePlayBillingClient {
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class _InAppPurchaseBillingClient implements GooglePlayBillingClient {
  final InAppPurchase _billing = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _billing.purchaseStream;

  @override
  Future<bool> isAvailable() => _billing.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _billing.queryProductDetails(ids);

  @override
  Future<bool> buyNonConsumable(PurchaseParam purchaseParam) =>
      _billing.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => _billing.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _billing.completePurchase(purchase);
}

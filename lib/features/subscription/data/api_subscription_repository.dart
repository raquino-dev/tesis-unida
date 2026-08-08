import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../domain/subscription_entity.dart';
import '../domain/subscription_repository.dart';
import 'google_play_billing_service.dart';

class ApiSubscriptionRepository implements SubscriptionRepository {
  final ApiClient _api;
  final GooglePlayBillingService _billing;
  List<SubscriptionPlan> _plans = const [];
  SubscriptionEntity? _current;

  ApiSubscriptionRepository(this._api, {GooglePlayBillingService? billing})
    : _billing = billing ?? GooglePlayBillingService();

  @override
  Future<SubscriptionEntity> getSubscription() async {
    _plans = await _loadPlans();
    try {
      final response = await _api.get('/suscripcion');
      return _current = _mapSubscription(response.object, _plans);
    } on AppFailure catch (failure) {
      if (failure.code != 'suscripcion_no_encontrada' &&
          failure.code != 'http_404') {
        rethrow;
      }
      return _current = SubscriptionEntity(
        status: SubscriptionStatus.free,
        currentPlan: PlanId.free,
        renewalDateLabel: '',
        plans: _plans,
      );
    }
  }

  @override
  Future<SubscriptionEntity> purchase(
    PlanId planId, [
    String verificationOtpId = '00000000-0000-0000-0000-000000000000',
  ]) async {
    if (planId == PlanId.free) {
      throw const AppFailure('Seleccioná un plan premium para continuar.');
    }
    if (_plans.isEmpty) await getSubscription();
    final plan = _plans.firstWhere((item) => item.id == planId);
    final products = await _billing.queryProducts({plan.productId});
    final product = products[plan.productId];
    if (product == null) {
      throw AppFailure(
        'El producto ${plan.productId} no está publicado para esta prueba.',
        code: 'product_not_found',
      );
    }
    final purchase = await _billing.purchase(product);
    _billing.validate(purchase);
    try {
      final current = _current;
      final response =
          current != null && current.isPremium && current.currentPlan != planId
          ? await _api.put(
              '/suscripcion/plan',
              headers: {
                'If-Match': '"${current.version}"',
                'Idempotency-Key': _idempotencyKey('change', purchase),
              },
              body: _purchaseBody(plan, purchase, verificationOtpId),
            )
          : await _api.post(
              '/suscripciones',
              headers: {
                'Idempotency-Key': _idempotencyKey('purchase', purchase),
              },
              body: _purchaseBody(plan, purchase, verificationOtpId),
            );
      await _billing.complete(purchase);
      return _current = _mapSubscription(response.object, _plans);
    } catch (_) {
      // No se confirma la compra al SDK si el backend no verificó el token.
      rethrow;
    }
  }

  @override
  Future<SubscriptionEntity> restorePurchase() async {
    if (_plans.isEmpty) await getSubscription();
    final premiumPlans = _plans
        .where((plan) => plan.id != PlanId.free)
        .toList(growable: false);
    final purchase = await _billing.restore(
      premiumPlans.map((plan) => plan.productId).toSet(),
    );
    _billing.validate(purchase);
    final response = await _api.post(
      '/restauraciones-suscripcion',
      body: {
        'proveedor': 'google-play',
        'comprobante': purchase.verificationData.serverVerificationData,
      },
    );
    await _billing.complete(purchase);
    return _current = _mapSubscription(response.object, _plans);
  }

  @override
  Future<SubscriptionEntity> cancel() async {
    final current = _current ?? await getSubscription();
    if (!current.isPremium) return current;
    final response = await _api.post(
      '/suscripcion/cancelaciones',
      headers: {
        'If-Match': '"${current.version}"',
        'Idempotency-Key': 'cancel-${DateTime.now().microsecondsSinceEpoch}',
      },
      body: {'motivo': 'Cancelada por el usuario desde la aplicación'},
    );
    return _current = _mapSubscription(response.object, _plans);
  }

  Future<List<SubscriptionPlan>> _loadPlans() async {
    final response = await _api.get(
      '/planes-suscripcion',
      authenticated: false,
    );
    final values = response.data as List? ?? const [];
    final plans = values
        .map((item) => _mapPlan(item as Map<String, dynamic>))
        .toList(growable: false);
    final products = await _billing.queryProducts(
      plans
          .where((plan) => plan.productId.isNotEmpty)
          .map((plan) => plan.productId)
          .toSet(),
    );
    return plans
        .map(
          (plan) => SubscriptionPlan(
            id: plan.id,
            code: plan.code,
            productId: plan.productId,
            name: plan.name,
            price: plan.price,
            storePrice: products[plan.productId]?.price,
            period: plan.period,
            features: plan.features,
            highlighted: plan.highlighted,
          ),
        )
        .toList(growable: false);
  }

  SubscriptionPlan _mapPlan(Map<String, dynamic> json) {
    final code = json['codigo'] as String;
    final id = _planId(code);
    return SubscriptionPlan(
      id: id,
      code: code,
      productId: switch (id) {
        PlanId.free => '',
        PlanId.premiumMonthly => AppEnvironment.googlePlayMonthlyProductId,
        PlanId.premiumAnnual => AppEnvironment.googlePlayAnnualProductId,
      },
      name: json['nombre'] as String,
      price: (json['precio'] as num).toDouble(),
      period: _periodLabel(json['periodo'] as String),
      features: (json['capacidades'] as List? ?? const [])
          .map((value) => _capabilityLabel(value as String))
          .toList(growable: false),
      highlighted: json['destacado'] as bool? ?? false,
    );
  }

  SubscriptionEntity _mapSubscription(
    Map<String, dynamic> json,
    List<SubscriptionPlan> plans,
  ) {
    final plan = json['plan'] as Map<String, dynamic>;
    final status = (json['estado'] as String).toLowerCase();
    return SubscriptionEntity(
      status: switch (status) {
        'activa' || 'active' => SubscriptionStatus.active,
        'vencida' || 'expired' => SubscriptionStatus.expired,
        _ => SubscriptionStatus.free,
      },
      currentPlan: _planId(plan['codigo'] as String),
      renewalDateLabel: DateTime.parse(
        json['finPeriodoEn'] as String,
      ).toLocal().toString().split(' ').first,
      plans: plans,
      version: (json['version'] as num).toInt(),
    );
  }

  Map<String, Object> _purchaseBody(
    SubscriptionPlan plan,
    PurchaseDetails purchase,
    String otpId,
  ) => {
    'planCodigo': plan.code,
    'proveedor': 'google-play',
    'comprobante': purchase.verificationData.serverVerificationData,
    'verificacionOtpId': otpId,
  };

  String _idempotencyKey(String action, PurchaseDetails purchase) =>
      '$action-${purchase.purchaseID ?? purchase.productID}';

  PlanId _planId(String code) => switch (code) {
    'premium-mensual' => PlanId.premiumMonthly,
    'premium-anual' => PlanId.premiumAnnual,
    _ => PlanId.free,
  };

  String _periodLabel(String period) => switch (period) {
    'mensual' => 'por mes',
    'anual' => 'por año',
    _ => period,
  };

  String _capabilityLabel(String capability) => switch (capability) {
    'ocr' => 'Escaneo OCR ilimitado',
    'predicciones' => 'Predicciones avanzadas',
    'exportaciones' => 'Exportación a PDF y Excel',
    'alertas-prioritarias' => 'Alertas inteligentes prioritarias',
    'cuentas' => 'Gestión de cuentas',
    'categorias' => 'Categorías personalizadas',
    'movimientos' => 'Registro de movimientos',
    _ => capability,
  };

  void dispose() => _billing.dispose();
}

import 'package:flutter/material.dart';

/// Fuente centralizada de datos ficticios (Paraguay / PYG). Ningún widget
/// debe leer de aquí directamente: siempre a través de un Repository mock.
/// Cuando exista backend real, basta con reemplazar las implementaciones
/// mock por servicios HTTP que devuelvan las mismas entidades de dominio.
class MockData {
  MockData._();

  // ---- Usuario ----
  static const String userId = 'usr_001';
  static const String userName = 'Rodrigo Aquino';
  static const String userEmail = 'rodrigo.aquino@correo.com.py';
  static const String userLocation = 'Asunción, Paraguay';
  static const String currencyCode = 'PYG';
  static const String language = 'Español';

  // ---- Resumen financiero mensual (coherente: 70.9M - 30.45M = 40.45M) ----
  static const double monthlyIncome = 70900000;
  static const double monthlyExpense = 30450000;
  static const double monthlyBalance = 40450000;
  static const double budgetTotal = 40500000;
  static const double budgetAvailable = 10050000;
  static const double budgetSpent = 30450000;
  static const int financialScore = 78;

  // ---- Categorías por defecto ----
  static final List<Map<String, dynamic>> categories = [
    {
      'id': 'cat_alimentacion',
      'name': 'Alimentación',
      'icon': Icons.restaurant_outlined,
      'color': const Color(0xFFF48139),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_transporte',
      'name': 'Transporte',
      'icon': Icons.directions_car_outlined,
      'color': const Color(0xFF2586E6),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_vivienda',
      'name': 'Vivienda',
      'icon': Icons.home_outlined,
      'color': const Color(0xFF6659E8),
      'type': 'expense',
      'inUse': false,
    },
    {
      'id': 'cat_servicios',
      'name': 'Servicios',
      'icon': Icons.bolt_outlined,
      'color': const Color(0xFFF5B72E),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_salud',
      'name': 'Salud',
      'icon': Icons.favorite_outline,
      'color': const Color(0xFFEC3E75),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_educacion',
      'name': 'Educación',
      'icon': Icons.school_outlined,
      'color': const Color(0xFF009B65),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_entretenimiento',
      'name': 'Entretenimiento',
      'icon': Icons.movie_outlined,
      'color': const Color(0xFFB946E8),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_compras',
      'name': 'Compras',
      'icon': Icons.shopping_bag_outlined,
      'color': const Color(0xFFEB40BE),
      'type': 'expense',
      'inUse': false,
    },
    {
      'id': 'cat_suscripciones',
      'name': 'Suscripciones',
      'icon': Icons.subscriptions_outlined,
      'color': const Color(0xFF2789E5),
      'type': 'expense',
      'inUse': true,
    },
    {
      'id': 'cat_ingresos',
      'name': 'Ingresos',
      'icon': Icons.savings_outlined,
      'color': const Color(0xFF00A96B),
      'type': 'income',
      'inUse': true,
    },
    {
      'id': 'cat_otros',
      'name': 'Otros',
      'icon': Icons.category_outlined,
      'color': const Color(0xFF718094),
      'type': 'both',
      'inUse': false,
    },
  ];

  // ---- Cuentas financieras ----
  static const List<Map<String, dynamic>> accounts = [
    {
      'id': 'acc_efectivo',
      'name': 'Efectivo',
      'type': 'cash',
      'icon': Icons.payments_outlined,
      'brand': 'none',
      'initialBalance': 850000.0,
      'isActive': true,
      'inUse': true,
    },
    {
      'id': 'acc_debito_continental',
      'name': 'Débito Continental',
      'type': 'debitCard',
      'icon': Icons.credit_card_outlined,
      'brand': 'visa',
      'initialBalance': 12500000.0,
      'isActive': true,
      'inUse': true,
    },
    {
      'id': 'acc_credito_itau',
      'name': 'Crédito Itaú',
      'type': 'creditCard',
      'icon': Icons.credit_card_rounded,
      'brand': 'mastercard',
      'initialBalance': 0.0,
      'isActive': true,
      'inUse': true,
    },
    {
      'id': 'acc_ahorros',
      'name': 'Caja de ahorro',
      'type': 'savingsAccount',
      'icon': Icons.savings_outlined,
      'brand': 'none',
      'initialBalance': 25000000.0,
      'isActive': true,
      'inUse': false,
    },
    {
      'id': 'acc_billetera_tigo',
      'name': 'Tigo Money',
      'type': 'digitalWallet',
      'icon': Icons.smartphone_outlined,
      'brand': 'none',
      'initialBalance': 430000.0,
      'isActive': true,
      'inUse': true,
    },
  ];

  // ---- Tarjetas de crédito ----
  static const List<Map<String, dynamic>> creditCards = [
    {
      'id': 'cc_itau',
      'alias': 'Itaú Mastercard',
      'accountId': 'acc_credito_itau',
      'closingDay': 20,
      'dueDay': 5,
      'totalLimit': 15000000.0,
      'usedLimit': 4200000.0,
    },
  ];

  // ---- Movimientos ----
  static List<Map<String, dynamic>> movements(DateTime now) => [
    {
      'id': 'mov_001',
      'type': 'expense',
      'amount': 285000.0,
      'date': now.subtract(const Duration(hours: 3)),
      'categoryIds': ['cat_alimentacion'],
      'description': 'Supermercado',
      'accountId': 'acc_debito_continental',
      'hasAttachment': true,
      'attachmentType': 'image',
      'ocrStatus': 'exitoso',
    },
    {
      'id': 'mov_002',
      'type': 'expense',
      'amount': 75000.0,
      'date': now.subtract(const Duration(hours: 6)),
      'categoryIds': ['cat_transporte'],
      'description': 'Transporte',
      'accountId': 'acc_efectivo',
      'hasAttachment': false,
      'attachmentType': null,
      'ocrStatus': null,
    },
    {
      'id': 'mov_003',
      'type': 'expense',
      'amount': 42000.0,
      'date': now.subtract(const Duration(days: 1, hours: 2)),
      'categoryIds': ['cat_alimentacion'],
      'description': 'Almuerzo',
      'accountId': 'acc_credito_itau',
      'hasAttachment': false,
      'attachmentType': null,
      'ocrStatus': null,
    },
    {
      'id': 'mov_004',
      'type': 'expense',
      'amount': 180000.0,
      'date': now.subtract(const Duration(days: 1, hours: 8)),
      'categoryIds': ['cat_servicios'],
      'description': 'Internet',
      'accountId': 'acc_debito_continental',
      'hasAttachment': true,
      'attachmentType': 'pdf',
      'ocrStatus': 'exitoso',
    },
    {
      'id': 'mov_005',
      'type': 'income',
      'amount': 7900000.0,
      'date': now.subtract(const Duration(days: 3)),
      'categoryIds': ['cat_ingresos'],
      'description': 'Salario',
      'accountId': 'acc_ahorros',
      'hasAttachment': false,
      'attachmentType': null,
      'ocrStatus': null,
    },
    {
      'id': 'mov_006',
      'type': 'expense',
      'amount': 55000.0,
      'date': now.subtract(const Duration(days: 4)),
      'categoryIds': ['cat_suscripciones'],
      'description': 'Suscripción streaming',
      'accountId': 'acc_credito_itau',
      'hasAttachment': false,
      'attachmentType': null,
      'ocrStatus': null,
    },
    {
      'id': 'mov_007',
      'type': 'expense',
      'amount': 96000.0,
      'date': now.subtract(const Duration(days: 5)),
      'categoryIds': ['cat_salud'],
      'description': 'Farmacia',
      'accountId': 'acc_efectivo',
      'hasAttachment': true,
      'attachmentType': 'image',
      'ocrStatus': 'incompleto',
    },
    {
      'id': 'mov_008',
      'type': 'expense',
      'amount': 650000.0,
      'date': now.subtract(const Duration(days: 7)),
      'categoryIds': ['cat_educacion'],
      'description': 'Universidad',
      'accountId': 'acc_billetera_tigo',
      'hasAttachment': true,
      'attachmentType': 'pdf',
      'ocrStatus': null,
    },
  ];

  // ---- Alertas inteligentes ----
  static const List<Map<String, dynamic>> alerts = [
    {
      'id': 'alert_001',
      'title': 'Gasto en transporte por encima del promedio',
      'message':
          'Tu gasto en transporte está 28% por encima del promedio de los últimos 3 meses.',
      'level': 'warning',
      'whatHappened':
          'Tus gastos en transporte durante este mes superan el promedio histórico calculado sobre los últimos 3 meses.',
      'dataUsed':
          'Movimientos categorizados como "Transporte" de los últimos 90 días.',
      'impact':
          'Si la tendencia continúa, tu presupuesto mensual de transporte podría agotarse antes de fin de mes.',
      'recommendation':
          'Revisá tus traslados recientes y considerá alternativas más económicas para los próximos días.',
    },
    {
      'id': 'alert_002',
      'title': 'Aumento en gastos variables',
      'message': 'Tus gastos variables aumentaron esta semana.',
      'level': 'info',
      'whatHappened':
          'Se detectó un incremento en categorías de gasto variable como entretenimiento y compras.',
      'dataUsed': 'Comparación semanal de movimientos por categoría.',
      'impact':
          'Impacto leve sobre tu balance proyectado si el patrón se mantiene.',
      'recommendation':
          'No es necesario actuar de inmediato. Solo tené presente esta tendencia.',
    },
    {
      'id': 'alert_003',
      'title': 'Presupuesto de alimentación cerca del límite',
      'message': 'Tu presupuesto de alimentación está cerca del límite.',
      'level': 'warning',
      'whatHappened':
          'Llevás consumido el 85% de tu presupuesto asignado a alimentación este mes.',
      'dataUsed':
          'Presupuesto definido para la categoría "Alimentación" y gasto acumulado del mes.',
      'impact':
          'Podrías excederte antes de fin de mes si mantenés el ritmo actual de gasto.',
      'recommendation':
          'Podés ajustar este presupuesto sin afectar tus gastos esenciales.',
    },
    {
      'id': 'alert_004',
      'title': 'Balance proyectado positivo',
      'message': 'Tu balance proyectado sigue siendo positivo.',
      'level': 'success',
      'whatHappened':
          'Con base en tu ritmo actual de ingresos y gastos, tu balance de fin de mes se mantiene positivo.',
      'dataUsed':
          'Ingresos y gastos registrados hasta la fecha en el mes actual.',
      'impact':
          'Vas bien este mes. Tu balance proyectado sigue siendo positivo.',
      'recommendation': 'Continuá con tus hábitos actuales de gasto.',
    },
  ];

  // ---- Predicciones ----
  static const double predictedExpense = 3850000;
  static const double predictedBalance = 4050000;
  static const String predictedGrowthCategory = 'Transporte';
  static const String predictedRisk = 'Bajo';

  static const List<Map<String, dynamic>> categoryPredictions = [
    {'category': 'Alimentación', 'projected': 1450000.0, 'variation': 0.06},
    {'category': 'Transporte', 'projected': 620000.0, 'variation': 0.28},
    {'category': 'Servicios', 'projected': 480000.0, 'variation': 0.02},
    {'category': 'Entretenimiento', 'projected': 310000.0, 'variation': -0.08},
    {'category': 'Salud', 'projected': 260000.0, 'variation': 0.04},
  ];

  static final List<Map<String, dynamic>> predictionHistory = List.generate(4, (
    i,
  ) {
    return {
      'month': DateTime.now().subtract(Duration(days: 30 * (i + 1))),
      'projected': 3600000.0 + (i * 90000),
      'actual': 3550000.0 + (i * 110000),
    };
  });

  // ---- Score financiero ----
  static const String scoreStatus = 'Equilibrado';
  static const List<String> scorePositiveFactors = [
    'Mantenés un balance mensual positivo de forma consistente.',
    'Tus gastos esenciales están dentro del presupuesto definido.',
    'Registrás tus movimientos con regularidad.',
  ];
  static const List<String> scoreNegativeFactors = [
    'Tu gasto en transporte muestra variabilidad reciente.',
    'Tenés poco margen en el presupuesto de alimentación.',
  ];
  static const List<String> scoreRecommendations = [
    'Fijá un límite semanal para transporte y revisalo cada domingo.',
    'Adelantá un pequeño ahorro apenas recibas tu ingreso principal.',
    'Revisá tus suscripciones activas una vez al mes.',
  ];
  static final List<Map<String, dynamic>> scoreHistory = List.generate(6, (i) {
    return {
      'month': DateTime.now().subtract(Duration(days: 30 * (5 - i))),
      'score': 62 + (i * 3),
    };
  });

  // ---- Presupuestos ----
  static const List<Map<String, dynamic>> categoryBudgets = [
    {
      'id': 'bud_alimentacion',
      'name': 'Alimentación',
      'categoryId': 'cat_alimentacion',
      'categoryIds': ['cat_alimentacion'],
      'period': 'monthly',
      'amount': 1600000.0,
      'spent': 1360000.0,
    },
    {
      'id': 'bud_transporte',
      'name': 'Transporte',
      'categoryId': 'cat_transporte',
      'categoryIds': ['cat_transporte'],
      'period': 'monthly',
      'amount': 700000.0,
      'spent': 690000.0,
    },
    {
      'id': 'bud_servicios',
      'name': 'Servicios',
      'categoryId': 'cat_servicios',
      'categoryIds': ['cat_servicios'],
      'period': 'monthly',
      'amount': 550000.0,
      'spent': 480000.0,
    },
    {
      'id': 'bud_salud',
      'name': 'Salud',
      'categoryId': 'cat_salud',
      'categoryIds': ['cat_salud'],
      'period': 'monthly',
      'amount': 400000.0,
      'spent': 96000.0,
    },
    {
      'id': 'bud_entretenimiento',
      'name': 'Ocio y entretenimiento',
      'categoryId': 'cat_entretenimiento',
      'categoryIds': ['cat_entretenimiento', 'cat_suscripciones'],
      'period': 'monthly',
      'amount': 350000.0,
      'spent': 410000.0,
    },
  ];

  // ---- Suscripción ----
  static const String subscriptionStatus = 'free';
  static const String renewalDateLabel = '06/08/2026';

  // ---- Exportaciones ----
  static final List<Map<String, dynamic>> exportHistory = [
    {
      'id': 'exp_001',
      'format': 'PDF',
      'range': 'Junio 2026',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'status': 'success',
    },
    {
      'id': 'exp_002',
      'format': 'CSV',
      'range': 'Mayo 2026',
      'date': DateTime.now().subtract(const Duration(days: 40)),
      'status': 'success',
    },
  ];
}

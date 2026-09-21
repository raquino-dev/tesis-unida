import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../domain/alert_entity.dart';
import '../domain/alert_repository.dart';
import '../../movements/domain/movement_repository.dart';

AlertLevel _levelFromString(String value) {
  switch (value) {
    case 'warning':
      return AlertLevel.warning;
    case 'error':
      return AlertLevel.error;
    case 'success':
      return AlertLevel.success;
    default:
      return AlertLevel.info;
  }
}

class MockAlertRepository implements AlertRepository {
  final MovementRepository movementRepository;
  MockAlertRepository(this.movementRepository);
  Future<List<AlertEntity>> _load() async {
    final movements = await movementRepository.getMovements();
    final expenses = movements
        .where((movement) => movement.analyticalExpenseAmount != 0)
        .toList();
    final total = expenses.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalExpenseAmount,
    );
    final transport = expenses
        .where(
          (movement) => movement.categories.any(
            (category) => category.id == 'cat_transporte',
          ),
        )
        .fold<double>(
          0,
          (sum, movement) => sum + movement.analyticalExpenseAmount,
        );
    final source = MockData.alerts
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    if (source.isNotEmpty) {
      source[0]['message'] =
          'Transporte representa ${total == 0 ? 0 : (transport / total * 100).toStringAsFixed(0)}% de tus gastos registrados.';
      source[0]['dataUsed'] =
          '${expenses.length} movimientos de gasto disponibles en el prototipo.';
    }
    final alerts = source.asMap().entries.map((entry) {
      final a = entry.value;
      return AlertEntity(
        id: a['id'] as String,
        title: a['title'] as String,
        message: a['message'] as String,
        level: _levelFromString(a['level'] as String),
        date: DateTime.now().subtract(Duration(days: entry.key)),
        whatHappened: a['whatHappened'] as String,
        dataUsed: a['dataUsed'] as String,
        impact: a['impact'] as String,
        recommendation: a['recommendation'] as String,
      );
    }).toList();
    return alerts;
  }

  @override
  Future<List<AlertEntity>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return _load();
  }

  @override
  Future<AlertEntity> getAlertById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final alerts = await _load();
    return alerts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw const AppFailure('Alerta no encontrada.'),
    );
  }

  @override
  Future<AlertEntity> markAsRead(String id) async =>
      (await getAlertById(id)).copyWith(isRead: true);

  @override
  Future<void> archive(String id) async {}
}

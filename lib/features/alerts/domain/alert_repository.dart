import 'alert_entity.dart';

abstract class AlertRepository {
  Future<List<AlertEntity>> getAlerts();
  Future<AlertEntity> getAlertById(String id);
  Future<AlertEntity> markAsRead(String id);
  Future<void> archive(String id);
}

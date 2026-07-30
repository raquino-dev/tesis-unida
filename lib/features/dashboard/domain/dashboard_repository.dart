import 'dashboard_summary_entity.dart';

abstract class DashboardRepository {
  Future<DashboardSummaryEntity> getSummary();
}

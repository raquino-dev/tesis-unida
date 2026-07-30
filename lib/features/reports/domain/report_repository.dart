import 'report_entity.dart';
import 'package:flutter/material.dart' show DateTimeRange;

abstract class ReportRepository {
  Future<ReportEntity> getReport(
    ReportRange range, {
    DateTimeRange? customRange,
  });
}

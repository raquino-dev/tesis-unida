enum AlertLevel { info, warning, error, success }

class AlertEntity {
  final String id;
  final String title;
  final String message;
  final AlertLevel level;
  final DateTime date;
  final String whatHappened;
  final String dataUsed;
  final String impact;
  final String recommendation;

  const AlertEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.level,
    required this.date,
    required this.whatHappened,
    required this.dataUsed,
    required this.impact,
    required this.recommendation,
  });
}

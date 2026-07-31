import '../../accounts/domain/account_entity.dart';
import '../../categories/domain/category_entity.dart';
import '../../movements/domain/movement_entity.dart';

enum RecurrenceFrequency { daily, weekly, biweekly, monthly, yearly }

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String get label {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diaria';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.biweekly:
        return 'Quincenal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.yearly:
        return 'Anual';
    }
  }

  Duration get approximateStep {
    switch (this) {
      case RecurrenceFrequency.daily:
        return const Duration(days: 1);
      case RecurrenceFrequency.weekly:
        return const Duration(days: 7);
      case RecurrenceFrequency.biweekly:
        return const Duration(days: 15);
      case RecurrenceFrequency.monthly:
        return const Duration(days: 30);
      case RecurrenceFrequency.yearly:
        return const Duration(days: 365);
    }
  }
}

enum RecurringStatus { active, paused, finished }

extension RecurringStatusLabel on RecurringStatus {
  String get label {
    switch (this) {
      case RecurringStatus.active:
        return 'Activo';
      case RecurringStatus.paused:
        return 'Pausado';
      case RecurringStatus.finished:
        return 'Finalizado';
    }
  }
}

class RecurringMovementEntity {
  final String id;
  final MovementType type;
  final double amount;
  final List<CategoryEntity> categories;
  final AccountEntity account;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final RecurrenceFrequency frequency;
  final int? totalOccurrences;
  final int completedOccurrences;
  final DateTime nextExecutionDate;
  final RecurringStatus status;
  final int version;

  const RecurringMovementEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.categories,
    required this.account,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.totalOccurrences,
    this.completedOccurrences = 0,
    required this.nextExecutionDate,
    this.status = RecurringStatus.active,
    this.version = 1,
  });

  bool get isIndefinite => endDate == null && totalOccurrences == null;

  RecurringMovementEntity copyWith({
    MovementType? type,
    double? amount,
    List<CategoryEntity>? categories,
    AccountEntity? account,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    RecurrenceFrequency? frequency,
    int? totalOccurrences,
    bool clearTotalOccurrences = false,
    int? completedOccurrences,
    DateTime? nextExecutionDate,
    RecurringStatus? status,
    int? version,
  }) {
    return RecurringMovementEntity(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categories: categories ?? this.categories,
      account: account ?? this.account,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      frequency: frequency ?? this.frequency,
      totalOccurrences: clearTotalOccurrences
          ? null
          : (totalOccurrences ?? this.totalOccurrences),
      completedOccurrences: completedOccurrences ?? this.completedOccurrences,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      status: status ?? this.status,
      version: version ?? this.version,
    );
  }
}

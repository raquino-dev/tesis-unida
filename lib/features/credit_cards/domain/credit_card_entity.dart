import '../../accounts/domain/account_entity.dart';

/// Tarjeta de crédito. La fecha de cierre se define mediante [closingDay]
/// (día del mes) y se proyecta automáticamente a los próximos meses; solo
/// se usa [closingDateOverride] cuando el usuario ajusta manualmente el
/// cierre de un mes puntual (p. ej. por un feriado bancario).
class CreditCardEntity {
  final String id;
  final String alias;
  final AccountEntity account;
  final int closingDay;
  final int dueDay;
  final DateTime? closingDateOverride;
  final double totalLimit;
  final double usedLimit;
  final String color;
  final int version;

  const CreditCardEntity({
    required this.id,
    required this.alias,
    required this.account,
    required this.closingDay,
    required this.dueDay,
    this.closingDateOverride,
    required this.totalLimit,
    required this.usedLimit,
    this.color = '#2586E6',
    this.version = 1,
  });

  /// La línea disponible siempre se deriva de total - utilizada, nunca se
  /// almacena por separado, evitando inconsistencias entre los tres valores.
  double get availableLimit => (totalLimit - usedLimit).clamp(0, totalLimit);

  double get usagePercentage =>
      totalLimit <= 0 ? 0 : (usedLimit / totalLimit).clamp(0, 1);

  DateTime get nextClosingDate {
    final now = DateTime.now();
    if (closingDateOverride != null &&
        !closingDateOverride!.isBefore(
          DateTime(now.year, now.month, now.day),
        )) {
      return closingDateOverride!;
    }
    final candidate = DateTime(now.year, now.month, closingDay);
    return candidate.isBefore(now)
        ? DateTime(now.year, now.month + 1, closingDay)
        : candidate;
  }

  DateTime get nextDueDate {
    final closing = nextClosingDate;
    final candidate = DateTime(closing.year, closing.month, dueDay);
    return candidate.isAfter(closing)
        ? candidate
        : DateTime(closing.year, closing.month + 1, dueDay);
  }

  CreditCardEntity copyWith({
    String? alias,
    AccountEntity? account,
    int? closingDay,
    int? dueDay,
    DateTime? closingDateOverride,
    bool clearClosingOverride = false,
    double? totalLimit,
    double? usedLimit,
    String? color,
    int? version,
  }) {
    return CreditCardEntity(
      id: id,
      alias: alias ?? this.alias,
      account: account ?? this.account,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      closingDateOverride: clearClosingOverride
          ? null
          : (closingDateOverride ?? this.closingDateOverride),
      totalLimit: totalLimit ?? this.totalLimit,
      usedLimit: usedLimit ?? this.usedLimit,
      color: color ?? this.color,
      version: version ?? this.version,
    );
  }
}

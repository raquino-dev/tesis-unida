import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String short(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String medium(DateTime date) =>
      DateFormat("d 'de' MMMM", 'es').format(date);

  static String full(DateTime date) =>
      DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'es').format(date);

  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return full(date);
  }
}

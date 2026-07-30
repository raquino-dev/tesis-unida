import 'package:intl/intl.dart';

/// Formatea montos en guaraníes paraguayos (PYG). El guaraní no usa
/// decimales en el uso cotidiano, por lo que se formatean como enteros.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('es_PY');

  static String format(num amount) {
    return 'Gs. ${_formatter.format(amount.round())}';
  }

  static String formatCompact(num amount) {
    final value = amount.abs();
    if (value >= 1000000000) {
      return 'Gs. ${(amount / 1000000000).toStringAsFixed(1)}mil M';
    }
    if (value >= 1000000) {
      return 'Gs. ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return 'Gs. ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return format(amount);
  }

  static String formatSigned(num amount) {
    final sign = amount > 0 ? '+' : (amount < 0 ? '-' : '');
    return '$sign${format(amount.abs())}';
  }
}

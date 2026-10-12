import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatea montos en guaraníes paraguayos (PYG). El guaraní no usa
/// decimales en el uso cotidiano, por lo que se formatean como enteros.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('es_PY');

  static String format(num amount) {
    return 'Gs. ${_formatter.format(amount.round())}';
  }

  /// Valor listo para mostrar dentro de un campo monetario.
  ///
  /// Los importes iguales a cero se dejan vacíos para que el usuario pueda
  /// empezar a escribir sin tener que borrar un `0` precargado.
  static String inputValue(num? amount) {
    if (amount == null || amount == 0) return '';
    return _formatter.format(amount.round());
  }

  /// Convierte el valor visual del campo (por ejemplo `1.250.000`) al monto
  /// que consumen los casos de uso y repositorios.
  static double parse(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return double.tryParse(digits) ?? 0;
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

/// Mantiene separadores de miles mientras se escribe un monto entero en PYG.
class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    final cursor = newValue.selection.end.clamp(0, rawText.length);
    final digitsBeforeCursor = rawText
        .substring(0, cursor)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final digits = rawText.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = _groupThousands(normalized);
    final selectionOffset = _cursorAfterDigits(
      formatted,
      digitsBeforeCursor.clamp(0, normalized.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  static int _cursorAfterDigits(String text, int digitCount) {
    if (digitCount <= 0) return 0;
    var seen = 0;
    for (var index = 0; index < text.length; index++) {
      if (_isDigit(text.codeUnitAt(index))) seen++;
      if (seen == digitCount) return index + 1;
    }
    return text.length;
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}

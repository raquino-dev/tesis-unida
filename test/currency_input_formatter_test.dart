import 'package:finanzas_app/core/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = CurrencyInputFormatter();

  TextEditingValue edit(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );

  test('agrega separadores de miles mientras se escribe', () {
    final result = formatter.formatEditUpdate(edit(''), edit('1234567'));

    expect(result.text, '1.234.567');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('elimina ceros iniciales y permite vaciar el campo', () {
    expect(formatter.formatEditUpdate(edit('0'), edit('0123')).text, '123');
    expect(formatter.formatEditUpdate(edit('1'), edit('')).text, '');
  });

  test('convierte el valor visual al importe completo', () {
    expect(CurrencyFormatter.parse('1.234.567'), 1234567);
    expect(CurrencyFormatter.parse(''), 0);
  });

  test('no precarga importes iguales a cero', () {
    expect(CurrencyFormatter.inputValue(0), '');
    expect(CurrencyFormatter.inputValue(null), '');
    expect(CurrencyFormatter.inputValue(1250000), '1.250.000');
  });
}

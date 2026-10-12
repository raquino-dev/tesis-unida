import 'dart:convert';

import 'package:finanzas_app/features/accounts/data/mock_account_repository.dart';
import 'package:finanzas_app/features/categories/data/mock_category_repository.dart';
import 'package:finanzas_app/features/export/data/statement_pdf_builder.dart';
import 'package:finanzas_app/features/movements/data/mock_movement_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('genera un extracto PDF válido con los movimientos', () async {
    final repository = MockMovementRepository(
      MockCategoryRepository(),
      MockAccountRepository(),
    );
    final movements = await repository.getMovements();
    final income = movements.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalIncomeAmount,
    );
    final expense = movements.fold<double>(
      0,
      (sum, movement) => sum + movement.analyticalExpenseAmount,
    );

    final bytes = await StatementPdfBuilder.build(
      period: '01/09/2026 - 30/09/2026',
      account: 'Todas las cuentas',
      generatedAt: DateTime(2026, 9, 22),
      totalIncome: income,
      totalExpense: expense,
      movementCount: movements.length,
      movements: movements,
    );

    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });
}

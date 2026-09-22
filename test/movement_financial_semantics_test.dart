import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/features/accounts/domain/account_entity.dart';
import 'package:finanzas_app/features/categories/domain/category_entity.dart';
import 'package:finanzas_app/features/movements/domain/movement_entity.dart';
import 'package:finanzas_app/features/movements/presentation/viewmodels/movement_list_viewmodel.dart';

void main() {
  const account = AccountEntity(
    id: 'account',
    name: 'Cuenta',
    type: AccountType.bankAccount,
    icon: Icons.account_balance,
    initialBalance: 100000,
  );
  const category = CategoryEntity(
    id: 'category',
    name: 'Compras',
    icon: Icons.shopping_bag,
    color: Colors.green,
    type: CategoryType.expense,
    inUse: true,
  );

  MovementEntity movement(CardOperation operation) => MovementEntity(
    id: operation.name,
    type: operation == CardOperation.purchase
        ? MovementType.expense
        : MovementType.income,
    amount: 25000,
    date: DateTime(2026, 9, 21),
    categories: const [category],
    description: operation.name,
    account: account,
    creditCardId: 'card',
    cardOperation: operation,
  );

  test('una compra con tarjeta suma al gasto', () {
    expect(movement(CardOperation.purchase).analyticalExpenseAmount, 25000);
  });

  test('un reintegro resta al gasto y no crea ingreso', () {
    final refund = movement(CardOperation.refund);
    expect(refund.analyticalExpenseAmount, -25000);
    expect(refund.analyticalIncomeAmount, 0);
  });

  test('un pago de tarjeta no crea ingreso ni gasto', () {
    final payment = movement(CardOperation.payment);
    expect(payment.analyticalExpenseAmount, 0);
    expect(payment.analyticalIncomeAmount, 0);
    expect(
      const MovementFilters(type: MovementType.income).matches(payment),
      isFalse,
    );
    expect(
      const MovementFilters(type: MovementType.expense).matches(payment),
      isFalse,
    );
    expect(
      const MovementFilters(accountId: 'account').matches(payment),
      isTrue,
    );
  });
}

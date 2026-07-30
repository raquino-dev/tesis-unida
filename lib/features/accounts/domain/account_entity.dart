import 'package:flutter/material.dart';

enum AccountType {
  cash,
  bankAccount,
  checkingAccount,
  savingsAccount,
  debitCard,
  creditCard,
  digitalWallet,
  other,
}

enum CardBrand { none, mastercard, visa, cabal, panal, americanExpress, other }

extension AccountTypeLabel on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bankAccount:
        return 'Cuenta bancaria';
      case AccountType.checkingAccount:
        return 'Cuenta corriente';
      case AccountType.savingsAccount:
        return 'Cuenta de ahorro';
      case AccountType.debitCard:
        return 'Tarjeta de débito';
      case AccountType.creditCard:
        return 'Tarjeta de crédito';
      case AccountType.digitalWallet:
        return 'Billetera digital';
      case AccountType.other:
        return 'Otro';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bankAccount:
        return Icons.account_balance_outlined;
      case AccountType.checkingAccount:
        return Icons.account_balance_wallet_outlined;
      case AccountType.savingsAccount:
        return Icons.savings_outlined;
      case AccountType.debitCard:
        return Icons.credit_card_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_rounded;
      case AccountType.digitalWallet:
        return Icons.smartphone_outlined;
      case AccountType.other:
        return Icons.wallet_outlined;
    }
  }

  bool get supportsBrand =>
      this == AccountType.debitCard || this == AccountType.creditCard;
}

extension CardBrandLabel on CardBrand {
  String get label {
    switch (this) {
      case CardBrand.none:
        return 'Sin marca';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.cabal:
        return 'Cabal';
      case CardBrand.panal:
        return 'Panal';
      case CardBrand.americanExpress:
        return 'American Express';
      case CardBrand.other:
        return 'Otra';
    }
  }
}

class AccountEntity {
  final String id;
  final String name;
  final AccountType type;
  final IconData icon;
  final CardBrand brand;
  final double initialBalance;
  final bool isActive;
  final bool inUse;

  const AccountEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.brand = CardBrand.none,
    required this.initialBalance,
    this.isActive = true,
    this.inUse = false,
  });

  AccountEntity copyWith({
    String? name,
    AccountType? type,
    IconData? icon,
    CardBrand? brand,
    double? initialBalance,
    bool? isActive,
  }) {
    return AccountEntity(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      brand: brand ?? this.brand,
      initialBalance: initialBalance ?? this.initialBalance,
      isActive: isActive ?? this.isActive,
      inUse: inUse,
    );
  }
}

import 'credit_card_entity.dart';

abstract class CreditCardRepository {
  Future<List<CreditCardEntity>> getCreditCards();
  Future<CreditCardEntity> createCreditCard(CreditCardEntity card);
  Future<CreditCardEntity> updateCreditCard(CreditCardEntity card);
  Future<void> deleteCreditCard(String id);
}

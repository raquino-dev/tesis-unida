import 'recurring_movement_entity.dart';

abstract class RecurringMovementRepository {
  Future<List<RecurringMovementEntity>> getRecurringMovements();
  Future<RecurringMovementEntity> createRecurringMovement(
    RecurringMovementEntity recurring,
  );
  Future<RecurringMovementEntity> updateRecurringMovement(
    RecurringMovementEntity recurring,
  );
  Future<RecurringMovementEntity> setStatus(
    RecurringMovementEntity recurring,
    RecurringStatus status,
  );
  Future<void> deleteRecurringMovement(String id);
}

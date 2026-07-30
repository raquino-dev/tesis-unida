import 'movement_entity.dart';

abstract class MovementRepository {
  Future<List<MovementEntity>> getMovements();
  Future<MovementEntity> getMovementById(String id);
  Future<MovementEntity> addMovement(MovementEntity movement);
  Future<MovementEntity> updateMovement(MovementEntity movement);
  Future<void> deleteMovement(String id);
  Future<MovementEntity> reprocessOcr(String id);
}

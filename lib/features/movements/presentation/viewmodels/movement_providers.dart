import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../data/mock_movement_repository.dart';
import '../../domain/movement_repository.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  return MockMovementRepository(
    ref.watch(categoryRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/account_providers.dart';
import '../../../categories/presentation/category_providers.dart';
import '../../data/mock_movement_repository.dart';
import '../../data/api_movement_repository.dart';
import '../../domain/movement_repository.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/network/api_providers.dart';

final movementRepositoryProvider = Provider<MovementRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiMovementRepository(
      ref.watch(apiClientProvider),
      ref.watch(categoryRepositoryProvider),
      ref.watch(accountRepositoryProvider),
    );
  }
  return MockMovementRepository(
    ref.watch(categoryRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
});

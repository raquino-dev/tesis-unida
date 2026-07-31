import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/services/pilot_local_store.dart';
import '../data/api_security_repository.dart';
import '../data/mock_security_repository.dart';
import '../domain/security_entity.dart';
import '../domain/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiSecurityRepository(ref.watch(apiClientProvider));
  }
  return MockSecurityRepository();
});

final securityEventsProvider = FutureProvider<List<SecurityEventEntity>>((ref) {
  return ref.watch(securityRepositoryProvider).getEvents();
});

final activeSessionsProvider = FutureProvider<List<ActiveSessionEntity>>((ref) {
  return ref.watch(securityRepositoryProvider).getActiveSessions();
});

final biometricsEnabledProvider = StateProvider<bool>(
  (ref) => PilotLocalStore.biometricsEnabled,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_security_repository.dart';
import '../domain/security_entity.dart';
import '../domain/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>(
  (ref) => MockSecurityRepository(),
);

final securityEventsProvider = FutureProvider<List<SecurityEventEntity>>((ref) {
  return ref.watch(securityRepositoryProvider).getEvents();
});

final biometricsEnabledProvider = StateProvider<bool>((ref) => false);

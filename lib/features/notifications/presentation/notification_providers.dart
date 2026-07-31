import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../core/network/api_providers.dart';
import '../data/notification_repository.dart';
import '../services/push_notification_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(apiClientProvider)),
);

final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(
  (ref) => ref.watch(notificationRepositoryProvider).getPreferences(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    ref.watch(notificationRepositoryProvider),
    ref.watch(appRouterProvider),
    rootNavigatorKey,
  );
  ref.onDispose(service.dispose);
  return service;
});

final pushInitializationProvider = FutureProvider<void>(
  (ref) => ref.watch(pushNotificationServiceProvider).initialize(),
);

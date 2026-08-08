import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/config/firebase_options.dart';
import '../../../core/services/pilot_local_store.dart';
import '../data/notification_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppEnvironment.firebaseConfigured) return;
  try {
    await Firebase.initializeApp(options: PilotFirebaseOptions.current);
  } catch (_) {
    // Firebase aún no está configurado en builds locales.
  }
}

class PushNotificationService {
  final NotificationRepository _repository;
  final GoRouter _router;
  final GlobalKey<NavigatorState> _navigatorKey;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  bool _available = false;

  PushNotificationService(this._repository, this._router, this._navigatorKey);

  Future<void> initialize() async {
    if (!AppEnvironment.firebaseConfigured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: PilotFirebaseOptions.current);
      }
      _available = true;
    } catch (_) {
      _available = false;
      return;
    }
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_openMessage),
    );
    _subscriptions.add(
      FirebaseMessaging.instance.onTokenRefresh.listen(
        _repository.registerPushToken,
      ),
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openMessage(initial),
      );
    }
    if (PilotLocalStore.pushNotifications && PilotLocalStore.hasSession) {
      await setEnabled(true);
    }
  }

  Future<bool> setEnabled(bool enabled) async {
    if (!_available) return false;
    if (!enabled) {
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      return true;
    }
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _repository.registerPushToken(token);
    }
    return true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    PilotLocalStore.recordMetric(
      'push_received_foreground',
      data: {'messageId': message.messageId},
    );
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final notification = message.notification;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          notification?.title ??
              notification?.body ??
              'Tenés una nueva notificación',
        ),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _openMessage(message),
        ),
      ),
    );
  }

  void _openMessage(RemoteMessage message) {
    final route = _routeFor(message.data);
    if (route == null) return;
    PilotLocalStore.recordMetric(
      'push_opened',
      data: {'messageId': message.messageId, 'route': route},
    );
    _router.go(route);
  }

  String? _routeFor(Map<String, dynamic> data) {
    final requested = data['route'] as String?;
    if (requested != null && _isAllowedRoute(requested)) return requested;
    final alertId = data['alertaId'] ?? data['alertId'];
    if (alertId is String && alertId.isNotEmpty) {
      return AppRoutes.alertDetailPath(alertId);
    }
    final movementId = data['movimientoId'] ?? data['movementId'];
    if (movementId is String && movementId.isNotEmpty) {
      return AppRoutes.movementDetailPath(movementId);
    }
    if (data['tipo'] == 'resumen-semanal') return AppRoutes.reports;
    return null;
  }

  bool _isAllowedRoute(String route) {
    const exact = {
      AppRoutes.dashboard,
      AppRoutes.alerts,
      AppRoutes.movements,
      AppRoutes.reports,
      AppRoutes.budgets,
      AppRoutes.predictions,
      AppRoutes.score,
      AppRoutes.subscription,
      AppRoutes.savingsGoals,
    };
    return exact.contains(route) ||
        route.startsWith('/alerts/') ||
        route.startsWith('/movements/');
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}

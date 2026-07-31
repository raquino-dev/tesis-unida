import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';
import '../core/config/app_environment.dart';
import '../core/services/pilot_local_store.dart';
import '../features/security/presentation/security_providers.dart';
import '../features/notifications/presentation/notification_providers.dart';

class FinanzasApp extends ConsumerWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushInitializationProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Finanzas Inteligentes',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Banner(
        message: AppEnvironment.useApi ? 'API' : 'DEMO',
        location: BannerLocation.topEnd,
        color: Theme.of(context).colorScheme.primary,
        child: _BiometricGate(child: child ?? const SizedBox.shrink()),
      ),
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

class _BiometricGate extends ConsumerStatefulWidget {
  final Widget child;

  const _BiometricGate({required this.child});

  @override
  ConsumerState<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<_BiometricGate>
    with WidgetsBindingObserver {
  bool _locked =
      PilotLocalStore.hasSession && PilotLocalStore.biometricsEnabled;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        PilotLocalStore.hasSession &&
        PilotLocalStore.biometricsEnabled) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating ||
        !PilotLocalStore.hasSession ||
        !PilotLocalStore.biometricsEnabled) {
      if (mounted && _locked) setState(() => _locked = false);
      return;
    }
    setState(() => _authenticating = true);
    final success = await ref
        .read(securityRepositoryProvider)
        .authenticateBiometrically();
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _locked = !success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Finanzas Inteligentes está bloqueada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirmá tu identidad para acceder a tu información.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _authenticating ? null : _unlock,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(_authenticating ? 'Verificando…' : 'Desbloquear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

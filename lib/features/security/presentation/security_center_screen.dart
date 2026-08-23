import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_failure.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import 'security_providers.dart';

class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(securityEventsProvider);
    final sessions = ref.watch(activeSessionsProvider);
    final biometrics = ref.watch(biometricsEnabledProvider);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad y auditoría')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            elevation: AppCardElevation.elevated,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Autenticación biométrica'),
                  subtitle: const Text(
                    'Usa la biometría configurada en este dispositivo',
                  ),
                  value: biometrics,
                  onChanged: (value) async {
                    try {
                      await ref
                          .read(securityRepositoryProvider)
                          .setBiometricsEnabled(value);
                      ref.read(biometricsEnabledProvider.notifier).state =
                          value;
                      ref.invalidate(securityEventsProvider);
                    } on AppFailure catch (failure) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        );
                      }
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Sesión protegida'),
                  subtitle: const Text(
                    AppEnvironment.useApi
                        ? 'JWT y refresh token protegidos en el dispositivo'
                        : 'JWT y refresh token de demostración',
                  ),
                  trailing: const Icon(Icons.check_circle_outline_rounded),
                ),
                if (biometrics) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.touch_app_rounded),
                    title: const Text('Probar desbloqueo biométrico'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final success = await ref
                          .read(securityRepositoryProvider)
                          .authenticateBiometrically();
                      ref.invalidate(securityEventsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Identidad verificada.'
                                  : 'No se pudo verificar la identidad.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sesiones activas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          sessions.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              appErrorMessage(
                error,
                fallback: 'No pudimos cargar las sesiones activas.',
              ),
            ),
            data: (items) => items.isEmpty
                ? Text(
                    'No hay sesiones activas.',
                    style: TextStyle(color: colors.textSecondary),
                  )
                : Column(
                    children: items
                        .map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.devices_rounded),
                                title: Text(session.deviceName),
                                subtitle: Text(
                                  '${session.platform} · vence ${DateFormatter.medium(session.expiresAt)}',
                                ),
                                trailing: session.current
                                    ? const Text('Actual')
                                    : IconButton(
                                        tooltip: 'Cerrar sesión',
                                        icon: const Icon(Icons.logout_rounded),
                                        onPressed: () async {
                                          await ref
                                              .read(securityRepositoryProvider)
                                              .revokeSession(session.id);
                                          ref.invalidate(
                                            activeSessionsProvider,
                                          );
                                          ref.invalidate(
                                            securityEventsProvider,
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Eventos de seguridad',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          events.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text(
              appErrorMessage(
                error,
                fallback: 'No pudimos cargar los eventos de seguridad.',
              ),
            ),
            data: (items) => items.isEmpty
                ? Text(
                    'Todavía no hay eventos registrados.',
                    style: TextStyle(color: colors.textSecondary),
                  )
                : Column(
                    children: items
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  event.successful
                                      ? Icons.verified_user_outlined
                                      : Icons.gpp_bad_outlined,
                                  color: event.successful
                                      ? colors.success
                                      : colors.error,
                                ),
                                title: Text(event.description),
                                subtitle: Text(
                                  DateFormatter.medium(event.occurredAt),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

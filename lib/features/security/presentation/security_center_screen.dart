import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import 'security_providers.dart';

class SecurityCenterScreen extends ConsumerWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(securityEventsProvider);
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
                    await ref
                        .read(securityRepositoryProvider)
                        .setBiometricsEnabled(value);
                    ref.read(biometricsEnabledProvider.notifier).state = value;
                    ref.invalidate(securityEventsProvider);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded),
                  title: const Text('Sesión protegida'),
                  subtitle: const Text(
                    'JWT y refresh token simulados en memoria',
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
            'Eventos de seguridad',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          events.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('$error'),
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

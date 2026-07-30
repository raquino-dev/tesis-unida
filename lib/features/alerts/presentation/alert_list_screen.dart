import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import 'alert_providers.dart';
import 'domain_helpers.dart';

class AlertListScreen extends ConsumerWidget {
  const AlertListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertListViewModelProvider);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Alertas inteligentes')),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(
          message: message,
          onRetry: ref.read(alertListViewModelProvider.notifier).load,
        ),
        empty: () => const AppEmptyState(
          icon: Icons.notifications_off_outlined,
          title: 'Sin alertas por ahora',
          message:
              'Te avisaremos apenas detectemos algo relevante sobre tus finanzas.',
        ),
        success: (alerts) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: alerts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            final tone = alertLevelTone(alert.level);
            return AppCard(
              onTap: () => context.push(AppRoutes.alertDetailPath(alert.id)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    alertLevelIcon(alert.level),
                    color: alertLevelColor(context, alert.level),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            AppBadge(
                              label: alertLevelLabel(alert.level),
                              tone: tone,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert.message,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormatter.medium(alert.date),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

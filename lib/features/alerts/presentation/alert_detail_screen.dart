import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import 'alert_providers.dart';
import 'domain_helpers.dart';

class AlertDetailScreen extends ConsumerWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAlert = ref.watch(alertDetailProvider(alertId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de alerta'),
        actions: [
          IconButton(
            tooltip: 'Archivar alerta',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await ref.read(alertRepositoryProvider).archive(alertId);
              ref.invalidate(alertListViewModelProvider);
              ref.invalidate(alertDetailProvider(alertId));
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: asyncAlert.when(
        loading: () => const AppLoadingState(),
        error: (e, _) =>
            const AppErrorState(message: 'No pudimos cargar la alerta.'),
        data: (alert) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    alertLevelIcon(alert.level),
                    color: alertLevelColor(context, alert.level),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _section(context, 'Qué pasó', alert.whatHappened),
              const SizedBox(height: AppSpacing.md),
              _section(context, 'Qué datos se usaron', alert.dataUsed),
              const SizedBox(height: AppSpacing.md),
              _section(context, 'Impacto posible', alert.impact),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendación',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.recommendation,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

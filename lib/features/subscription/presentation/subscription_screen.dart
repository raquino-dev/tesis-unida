import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_state_view.dart';
import '../domain/subscription_entity.dart';
import 'subscription_viewmodel.dart';
import '../../security/domain/security_entity.dart';
import '../../security/presentation/security_providers.dart';
import '../../security/presentation/widgets/otp_verification_dialog.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionViewModelProvider);
    final viewModel = ref.read(subscriptionViewModelProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Finanza Premium')),
      body: state.when(
        loading: () => const AppLoadingState(message: 'Procesando...'),
        error: (message) =>
            AppErrorState(message: message, onRetry: viewModel.load),
        empty: () => const AppEmptyState(
          title: 'Sin información',
          message: 'No pudimos encontrar tu plan.',
        ),
        success: (subscription) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.forest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: const Color(0xFFFFC14C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estado actual',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _planName(subscription),
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subscription.status == SubscriptionStatus.active) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Se renueva el ${subscription.renewalDateLabel}',
                      style: const TextStyle(
                        color: AppColors.textMutedDark,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (subscription.status == SubscriptionStatus.expired) ...[
                    const SizedBox(height: 8),
                    const AppBadge(
                      label: 'Suscripción vencida',
                      tone: AppBadgeTone.error,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...subscription.plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlanCard(
                  plan: plan,
                  isCurrent: plan.id == subscription.currentPlan,
                  onSelect: () async {
                    final verificationId = await requestOtpVerification(
                      context,
                      ref,
                      reason: 'Activar plan premium',
                    );
                    if (verificationId == null) return;
                    await viewModel.purchase(plan.id, verificationId);
                    await ref
                        .read(securityRepositoryProvider)
                        .recordEvent(
                          SecurityEventType.criticalAction,
                          'Suscripción premium activada',
                        );
                    ref.invalidate(securityEventsProvider);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Restaurar compra',
              variant: AppButtonVariant.ghost,
              onPressed: viewModel.restore,
            ),
            if (subscription.isPremium) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Cancelar suscripción',
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar suscripción'),
                      content: const Text(
                        'Volverás al plan gratuito y conservarás tus datos.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Volver'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await viewModel.cancel();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _planName(SubscriptionEntity s) {
    switch (s.currentPlan) {
      case PlanId.free:
        return 'Plan Free';
      case PlanId.premiumMonthly:
        return 'Premium mensual';
      case PlanId.premiumAnnual:
        return 'Premium anual';
    }
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrent;
  final Future<void> Function() onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      elevation: plan.highlighted
          ? AppCardElevation.elevated
          : AppCardElevation.surface,
      border: plan.highlighted
          ? Border.all(color: colors.primary.withValues(alpha: 0.5))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCurrent)
                const AppBadge(label: 'Plan actual', tone: AppBadgeTone.info)
              else if (plan.highlighted)
                const AppBadge(
                  label: 'Recomendado',
                  tone: AppBadgeTone.premium,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.price == 0
                ? 'Gratis'
                : plan.storePrice != null
                ? '${plan.storePrice} ${plan.period}'
                : '${CurrencyFormatter.format(plan.price)} ${plan.period}',
            style: TextStyle(
              color: colors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 16, color: colors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrent && plan.id != PlanId.free) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Elegir plan',
              onPressed: () => onSelect(),
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}

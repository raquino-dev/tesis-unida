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
import 'subscription_purchase_result_screen.dart';
import '../../security/domain/security_entity.dart';
import '../../security/presentation/security_providers.dart';
import '../../security/presentation/widgets/otp_verification_dialog.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
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
                  if (subscription.renews) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Se renueva el ${subscription.renewalDateLabel}',
                      style: const TextStyle(
                        color: AppColors.textMutedDark,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (subscription.status == SubscriptionStatus.cancelled) ...[
                    const SizedBox(height: 8),
                    AppBadge(
                      label: subscription.hasRenewalDate
                          ? 'Cancelada · acceso hasta ${subscription.renewalDateLabel}'
                          : 'Suscripción cancelada',
                      tone: AppBadgeTone.warning,
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
                  onSelect: () =>
                      _purchasePlan(context, ref, viewModel, plan.id),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Restaurar compra',
              variant: AppButtonVariant.ghost,
              isLoading: _restoring,
              onPressed: _restoring ? null : () => _restorePurchase(viewModel),
            ),
            if (subscription.status == SubscriptionStatus.active &&
                subscription.currentPlan != PlanId.free) ...[
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
                        'La renovación quedará cancelada. Mantendrás el acceso Premium hasta el final del período actual.',
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

  Future<void> _restorePurchase(SubscriptionViewModel viewModel) async {
    setState(() => _restoring = true);
    final outcome = await viewModel.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.succeeded
              ? 'Tu compra se restauró correctamente.'
              : outcome.errorMessage ?? 'No pudimos restaurar tu compra.',
        ),
      ),
    );
  }

  Future<void> _purchasePlan(
    BuildContext context,
    WidgetRef ref,
    SubscriptionViewModel viewModel,
    PlanId plan,
  ) async {
    final verificationId = await requestOtpVerification(
      context,
      ref,
      reason: 'Activar plan premium',
    );
    if (verificationId == null || !context.mounted) return;

    final outcome = await viewModel.purchase(plan, verificationId);
    if (!context.mounted) return;
    if (outcome.succeeded) {
      await ref
          .read(securityRepositoryProvider)
          .recordEvent(
            SecurityEventType.criticalAction,
            'Suscripción premium activada',
          );
      ref.invalidate(securityEventsProvider);
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => SubscriptionPurchaseResultScreen.success(
            subscription: outcome.subscription!,
          ),
        ),
      );
      return;
    }

    final action = await Navigator.of(context).push<SubscriptionPurchaseAction>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SubscriptionPurchaseResultScreen.failure(
          errorMessage:
              outcome.errorMessage ?? 'No pudimos procesar la compra.',
        ),
      ),
    );
    if (!context.mounted) return;
    await viewModel.load();
    if (action == null || !context.mounted) return;
    await _purchasePlan(context, ref, viewModel, plan);
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
    final currentPlanGradient = LinearGradient(
      colors: [
        Color.alphaBlend(
          colors.primary.withValues(alpha: 0.14),
          colors.surface,
        ),
        Color.alphaBlend(
          colors.primary.withValues(alpha: 0.05),
          colors.surface,
        ),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AppCard(
      elevation: isCurrent || plan.highlighted
          ? AppCardElevation.elevated
          : AppCardElevation.surface,
      gradient: isCurrent ? currentPlanGradient : null,
      border: isCurrent
          ? Border.all(
              color: colors.primary.withValues(alpha: 0.65),
              width: 1.4,
            )
          : plan.highlighted
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
                const AppBadge(
                  label: 'Plan actual',
                  tone: AppBadgeTone.success,
                  icon: Icons.check_rounded,
                )
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

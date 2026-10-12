import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/subscription_entity.dart';

enum SubscriptionPurchaseAction { retry, changePayment }

class SubscriptionPurchaseResultScreen extends StatelessWidget {
  final SubscriptionEntity? subscription;
  final String? errorMessage;

  const SubscriptionPurchaseResultScreen.success({
    super.key,
    required SubscriptionEntity this.subscription,
  }) : errorMessage = null;

  const SubscriptionPurchaseResultScreen.failure({
    super.key,
    required String this.errorMessage,
  }) : subscription = null;

  bool get _succeeded => subscription != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _succeeded
                ? [colors.background, colors.successBg.withValues(alpha: 0.35)]
                : [colors.background, colors.errorBg.withValues(alpha: 0.34)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _StatusIllustration(success: _succeeded),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          _succeeded
                              ? '¡Pago realizado\ncon éxito!'
                              : 'No pudimos procesar\ntu pago',
                          key: ValueKey(
                            _succeeded ? 'purchase-success' : 'purchase-error',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 30,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _succeeded
                              ? 'Tu suscripción ya está activa.\nGracias por confiar en Finanza.'
                              : 'Ocurrió un problema al procesar tu pago.\nIntentá nuevamente o verificá tu método de pago.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 16,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _succeeded
                            ? _SuccessDetails(subscription: subscription!)
                            : _FailureDetails(message: errorMessage!),
                        if (_succeeded) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.successBg.withValues(alpha: 0.55),
                              borderRadius: AppRadius.lgRadius,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.mail_outline_rounded,
                                  color: colors.success,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Te enviamos un correo con los detalles de tu suscripción.',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_succeeded)
                  AppButton(
                    label: 'Continuar',
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else ...[
                  AppButton(
                    label: 'Intentar nuevamente',
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(SubscriptionPurchaseAction.retry),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OutlinedPillButton(
                    label: 'Cambiar método de pago',
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(SubscriptionPurchaseAction.changePayment),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIllustration extends StatelessWidget {
  final bool success;

  const _StatusIllustration({required this.success});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = success ? colors.success : colors.error;
    return SizedBox(
      width: 180,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 144,
            height: 144,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              success ? Icons.check_rounded : Icons.priority_high_rounded,
              size: 58,
              color: Colors.white,
            ),
          ),
          ...const [
            Alignment(-0.85, -0.45),
            Alignment(0.82, -0.55),
            Alignment(-0.98, 0.58),
            Alignment(0.96, 0.5),
          ].map(
            (alignment) => Align(
              alignment: alignment,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDetails extends StatelessWidget {
  final SubscriptionEntity subscription;

  const _SuccessDetails({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      children: [
        _DetailRow(
          icon: Icons.workspace_premium_outlined,
          label: 'Plan',
          value: _planName(subscription.currentPlan),
        ),
        _DetailRow(
          icon: Icons.calendar_month_outlined,
          label: 'Inicio',
          value: _formattedDate(subscription.startedDateLabel),
        ),
        if (subscription.hasRenewalDate)
          _DetailRow(
            icon: Icons.event_repeat_rounded,
            label: 'Próximo cobro',
            value: _formattedDate(subscription.renewalDateLabel),
          ),
        _DetailRow(
          icon: Icons.payment_rounded,
          label: 'Método de pago',
          value: subscription.paymentMethodLabel.isEmpty
              ? 'Google Play'
              : subscription.paymentMethodLabel,
          isLast: true,
        ),
      ],
    );
  }
}

class _FailureDetails extends StatelessWidget {
  final String message;

  const _FailureDetails({required this.message});

  @override
  Widget build(BuildContext context) {
    return _DetailsPanel(
      children: [
        _DetailRow(
          icon: Icons.credit_card_rounded,
          label: 'Posible causa',
          value: message,
        ),
        const _DetailRow(
          icon: Icons.help_outline_rounded,
          label: 'Qué podés hacer',
          value:
              'Verificá los datos de tu tarjeta, asegurate de tener saldo disponible e intentá nuevamente.',
          isLast: true,
        ),
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  final List<Widget> children;

  const _DetailsPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlinedPillButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

String _planName(PlanId plan) => switch (plan) {
  PlanId.free => 'Plan Free',
  PlanId.premiumMonthly => 'Finanza Premium mensual',
  PlanId.premiumAnnual => 'Finanza Premium anual',
};

String _formattedDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value.isEmpty ? 'Hoy' : value;
  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  return '${date.day} de ${months[date.month - 1]} de ${date.year}';
}

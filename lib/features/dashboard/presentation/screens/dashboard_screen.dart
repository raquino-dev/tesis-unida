import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/widgets/finanza_mark.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../movements/domain/movement_entity.dart';
import '../../../movements/presentation/viewmodels/movement_providers.dart';
import '../../../movements/presentation/widgets/movement_card.dart';
import '../../../movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../domain/dashboard_summary_entity.dart';
import '../viewmodels/dashboard_viewmodel.dart';

final _recentMovementsProvider =
    FutureProvider.autoDispose<List<MovementEntity>>((ref) async {
      ref.watch(dashboardViewModelProvider);
      final movements = [
        ...await ref.watch(movementRepositoryProvider).getMovements(),
      ];
      movements.sort((a, b) => b.date.compareTo(a.date));
      return movements.take(4).toList(growable: false);
    });

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);
    final viewModel = ref.read(dashboardViewModelProvider.notifier);
    final recentMovements = ref.watch(_recentMovementsProvider);

    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const AppLoadingState(),
          error: (message) =>
              AppErrorState(message: message, onRetry: viewModel.load),
          empty: () => const AppEmptyState(
            title: 'Sin datos',
            message: 'Todavía no hay información financiera.',
          ),
          success: (summary) => RefreshIndicator(
            onRefresh: () async {
              await viewModel.load();
              ref.invalidate(_recentMovementsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                const FinanzaWordmark(compact: true),
                const SizedBox(height: AppSpacing.lg),
                _Greeting(name: summary.userName),
                const SizedBox(height: AppSpacing.lg),
                _BalanceCard(summary: summary),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Ingresos del mes',
                        value: summary.totalIncome,
                        tone: AppBadgeToneSuccess.success,
                        movementType: MovementType.income,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricTile(
                        label: 'Gastos del mes',
                        value: summary.totalExpense,
                        tone: AppBadgeToneSuccess.error,
                        movementType: MovementType.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _ScoreAndBudgetRow(summary: summary),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Cuentas',
                        onTap: () => context.push(AppRoutes.accounts),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.pie_chart_outline_rounded,
                        label: 'Presupuesto',
                        onTap: () => context.push(AppRoutes.budgets),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.savings_outlined,
                        label: 'Metas',
                        onTap: () => context.push(AppRoutes.savingsGoals),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: 'Movimientos recientes',
                  actionLabel: 'Ver todos',
                  onAction: () => context.go(AppRoutes.movements),
                ),
                const SizedBox(height: AppSpacing.sm),
                recentMovements.when(
                  loading: () => const AppCard(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const _DashboardEmptyCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'No pudimos mostrar los movimientos',
                    message: 'Podés consultarlos desde Movimientos.',
                  ),
                  data: (items) => items.isEmpty
                      ? _DashboardEmptyCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'Aún no hay movimientos',
                          message: 'Registrá tu primer ingreso o gasto.',
                          actionLabel: 'Agregar movimiento',
                          onAction: () => context.push(AppRoutes.addMovement),
                        )
                      : AppCard(
                          child: Column(
                            children: [
                              for (var i = 0; i < items.length; i++) ...[
                                if (i > 0) const Divider(height: 1),
                                MovementCard(
                                  movement: items[i],
                                  onTap: () => context.push(
                                    AppRoutes.movementDetailPath(items[i].id),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: 'Categorías principales',
                  actionLabel: summary.topCategories.isEmpty
                      ? 'Agregar categoría'
                      : 'Ver reportes',
                  onAction: () => context.push(
                    summary.topCategories.isEmpty
                        ? AppRoutes.categories
                        : AppRoutes.reports,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (summary.topCategories.isEmpty)
                  _DashboardEmptyCard(
                    icon: Icons.category_outlined,
                    title: 'Aún no tenés categorías con movimientos',
                    message:
                        'Agregá una categoría y registrá movimientos para ver cómo se distribuyen tus gastos.',
                    actionLabel: 'Gestionar categorías',
                    onAction: () => context.push(AppRoutes.categories),
                  )
                else
                  AppCard(
                    child: Column(
                      children: summary.topCategories.map((tc) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: tc.category.color.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(
                                  tc.category.icon,
                                  size: 18,
                                  color: tc.category.color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tc.category.name,
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: tc.percentage,
                                        minHeight: 5,
                                        backgroundColor:
                                            context.colors.surfaceElevated,
                                        valueColor: AlwaysStoppedAnimation(
                                          tc.category.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                CurrencyFormatter.formatCompact(tc.amount),
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(
                  title: 'Alertas inteligentes',
                  actionLabel: 'Ver todas',
                  onAction: () => context.push(AppRoutes.alerts),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (summary.alertHighlights.isEmpty)
                  const _DashboardEmptyCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'No hay alertas por ahora',
                    message:
                        'Tus finanzas no requieren una acción inmediata. Te avisaremos si detectamos algo importante.',
                  )
                else
                  ...summary.alertHighlights.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppCard(
                        elevation: AppCardElevation.elevated,
                        child: Row(
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              color: context.colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a,
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppSectionHeader(title: 'Próximos gastos recurrentes'),
                const SizedBox(height: AppSpacing.sm),
                if (summary.upcomingRecurring.isEmpty)
                  _DashboardEmptyCard(
                    icon: Icons.event_repeat_outlined,
                    title: 'No tenés gastos recurrentes próximos',
                    message:
                        'Configurá uno para anticipar pagos como alquiler, servicios o suscripciones.',
                    actionLabel: 'Crear gasto recurrente',
                    onAction: () => context.push(AppRoutes.recurringMovements),
                  )
                else
                  AppCard(
                    child: Column(
                      children: summary.upcomingRecurring.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.medium(item.date),
                                    style: TextStyle(
                                      color: context.colors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(item.amount),
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  const _DashboardEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

enum AppBadgeToneSuccess { success, error }

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final firstName = name.split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $firstName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.monthYear(DateTime.now()),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              if (!AppEnvironment.useApi)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: AppBadge(label: 'Modo demo'),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: colors.primary.withValues(alpha: 0.2),
            child: Text(
              firstName[0],
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, color: context.colors.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  final DashboardSummaryEntity summary;
  const _BalanceCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.emerald, AppColors.forest],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance del mes',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(summary.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.balance >= 0
                ? 'Vas bien este mes. Tus ingresos superan tus gastos.'
                : 'Tus gastos superan tus ingresos este mes.',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends ConsumerWidget {
  final String label;
  final double value;
  final AppBadgeToneSuccess tone;
  final MovementType movementType;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tone,
    required this.movementType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accent = tone == AppBadgeToneSuccess.success
        ? colors.success
        : colors.error;
    return AppCard(
      onTap: () {
        final viewModel = ref.read(movementListViewModelProvider.notifier);
        viewModel.updateFilters(viewModel.filters.copyWith(type: movementType));
        context.go(AppRoutes.movements);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tone == AppBadgeToneSuccess.success
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreAndBudgetRow extends StatelessWidget {
  final DashboardSummaryEntity summary;
  const _ScoreAndBudgetRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: () => context.push(AppRoutes.score),
            elevation: AppCardElevation.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score financiero',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.financialScore}',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2),
                      child: Text(
                        '/100',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppCard(
            onTap: () => context.push(AppRoutes.budgets),
            elevation: AppCardElevation.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto disponible',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatCompact(summary.budgetAvailable),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

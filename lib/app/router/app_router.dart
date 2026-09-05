import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounts/presentation/account_list_screen.dart';
import '../../features/alerts/presentation/alert_detail_screen.dart';
import '../../features/alerts/presentation/alert_list_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../core/services/pilot_local_store.dart';
import '../../core/widgets/offline_status_bar.dart';
import '../../features/budgets/presentation/budgets_screen.dart';
import '../../features/categories/presentation/category_list_screen.dart';
import '../../features/credit_cards/presentation/credit_card_list_screen.dart';
import '../../features/export/presentation/export_screen.dart';
import '../../features/family/presentation/family_screen.dart';
import '../../features/family/presentation/family_finance_screen.dart';
import '../../features/family/presentation/invitation_acceptance_screen.dart';
import '../../features/movements/domain/movement_entity.dart';
import '../../features/movements/presentation/screens/add_edit_movement_screen.dart';
import '../../features/movements/presentation/screens/movement_detail_screen.dart';
import '../../features/movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../features/ocr/presentation/screens/ocr_scan_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/predictions/presentation/predictions_screen.dart';
import '../../features/recurring_movements/presentation/recurring_movement_list_screen.dart';
import '../../features/score/presentation/score_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/transfers/presentation/transfer_screen.dart';
import '../../features/security/presentation/security_center_screen.dart';
import '../../features/pilot/presentation/pilot_center_screen.dart';
import '../../features/savings_goals/presentation/savings_goals_screen.dart';
import 'app_routes.dart';
import 'app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  // Una marca local no basta para abrir áreas privadas: el perfil debe haberse
  // restaurado desde la API o desde la caché cifrada del modo sin conexión.
  final authenticated = currentUser != null;
  const publicRoutes = {
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
    AppRoutes.resetPassword,
  };
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: !PilotLocalStore.onboardingCompleted
        ? AppRoutes.onboarding
        : authenticated
        ? AppRoutes.dashboard
        : AppRoutes.login,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!PilotLocalStore.onboardingCompleted &&
          location != AppRoutes.onboarding &&
          location != AppRoutes.resetPassword) {
        return AppRoutes.onboarding;
      }
      if (!authenticated && !publicRoutes.contains(location)) {
        return AppRoutes.login;
      }
      if (authenticated &&
          !PilotLocalStore.consentAccepted &&
          location != AppRoutes.pilot &&
          location != AppRoutes.resetPassword) {
        return AppRoutes.pilot;
      }
      if (authenticated &&
          publicRoutes.contains(location) &&
          location != AppRoutes.resetPassword) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          recoveryId: state.uri.queryParameters['recoveryId'],
          initialCode: state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: AppRoutes.addMovement,
        builder: (context, state) =>
            AddEditMovementScreen(initialType: state.extra as MovementType?),
      ),
      GoRoute(
        path: '/movements/:id/edit',
        builder: (context, state) =>
            AddEditMovementScreen(existing: state.extra as MovementEntity?),
      ),
      GoRoute(
        path: '/movements/:id',
        builder: (context, state) =>
            MovementDetailScreen(movementId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.accounts,
        builder: (context, state) => const AccountListScreen(),
      ),
      GoRoute(
        path: AppRoutes.ocr,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Escaneo de comprobantes',
          child: OcrScanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.budgets,
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const AlertListScreen(),
      ),
      GoRoute(
        path: '/alerts/:id',
        builder: (context, state) =>
            AlertDetailScreen(alertId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.predictions,
        builder: (context, state) => const PredictionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.score,
        builder: (context, state) => const ScoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Suscripciones',
          child: SubscriptionScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (context, state) => const SecurityCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pilot,
        builder: (context, state) => const PilotCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.savingsGoals,
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.export,
        builder: (context, state) => OnlineRequired(
          featureName: 'Exportación de datos',
          child: ExportScreen(
            initialFilters:
                state.extra as MovementFilters? ?? const MovementFilters(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.creditCards,
        builder: (context, state) => const CreditCardListScreen(),
      ),
      GoRoute(
        path: AppRoutes.transfers,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Transferencias entre cuentas',
          child: TransferScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.recurringMovements,
        builder: (context, state) => const RecurringMovementListScreen(),
      ),
      GoRoute(
        path: AppRoutes.family,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Colaboración familiar',
          child: FamilyScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.invitationAcceptance,
        builder: (context, state) => OnlineRequired(
          featureName: 'Invitación familiar',
          child: InvitationAcceptanceScreen(
            initialCode: state.uri.queryParameters['code'],
            initialToken: state.uri.queryParameters['token'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.familyTreasury,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Finanzas familiares',
          child: FamilyFinanceScreen(initialIndex: 0),
        ),
      ),
      GoRoute(
        path: AppRoutes.familyBudgets,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Presupuestos familiares',
          child: FamilyFinanceScreen(initialIndex: 1),
        ),
      ),
      GoRoute(
        path: AppRoutes.familyReports,
        builder: (context, state) => const OnlineRequired(
          featureName: 'Reportes familiares',
          child: FamilyFinanceScreen(initialIndex: 2),
        ),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const AppShell(initialIndex: 3),
      ),
      GoRoute(
        path: AppRoutes.movements,
        builder: (context, state) => const AppShell(initialIndex: 1),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const AppShell(initialIndex: 4),
      ),
    ],
  );
});

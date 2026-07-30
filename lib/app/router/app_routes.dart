/// Nombres y paths centralizados de navegación.
class AppRoutes {
  AppRoutes._();

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const invitationAcceptance = '/family/invitations/accept';
  static const pilot = '/pilot';

  static const dashboard = '/dashboard';
  static const movements = '/movements';
  static const addMovement = '/movements/add';
  static const reports = '/reports';
  static const profile = '/profile';

  static const categories = '/categories';
  static const accounts = '/accounts';
  static const ocr = '/ocr';
  static const budgets = '/budgets';
  static const alerts = '/alerts';
  static const predictions = '/predictions';
  static const score = '/score';
  static const subscription = '/subscription';
  static const settings = '/settings';
  static const security = '/security';
  static const changePassword = '/change-password';
  static const export = '/export';
  static const creditCards = '/credit-cards';
  static const transfers = '/transfers';
  static const recurringMovements = '/recurring-movements';
  static const family = '/family';
  static const savingsGoals = '/savings-goals';
  static const familyTreasury = '/family/treasury';
  static const familyBudgets = '/family/budgets';
  static const familyReports = '/family/reports';

  static String movementDetailPath(String id) => '/movements/$id';
  static String movementEditPath(String id) => '/movements/$id/edit';
  static String alertDetailPath(String id) => '/alerts/$id';
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../app/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../security/presentation/security_providers.dart';
import '../../../core/services/pilot_local_store.dart';
import '../../notifications/presentation/notification_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = PilotLocalStore.pushNotifications;
  bool _weeklySummary = PilotLocalStore.weeklySummary;
  bool _savingNotifications = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final biometrics = ref.watch(biometricsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sectionLabel(context, 'General'),
          AppCard(
            child: Column(
              children: [
                _switchTile(
                  context,
                  Icons.dark_mode_outlined,
                  'Tema oscuro',
                  themeMode == ThemeMode.dark,
                  (v) => ref
                      .read(themeModeProvider.notifier)
                      .setMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(context, Icons.language_rounded, 'Idioma', 'Español'),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.attach_money_rounded,
                  'Moneda',
                  'Guaraní (PYG)',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Cuentas y categorías'),
          AppCard(
            child: Column(
              children: [
                _navTile(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Cuentas',
                  '',
                  onTap: () => context.push(AppRoutes.accounts),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.category_outlined,
                  'Categorías',
                  '',
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.credit_card_outlined,
                  'Tarjetas de crédito',
                  '',
                  onTap: () => context.push(AppRoutes.creditCards),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.swap_horiz_rounded,
                  'Transferencias',
                  '',
                  onTap: () => context.push(AppRoutes.transfers),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.autorenew_rounded,
                  'Movimientos recurrentes',
                  '',
                  onTap: () => context.push(AppRoutes.recurringMovements),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.flag_outlined,
                  'Metas de ahorro',
                  '',
                  onTap: () => context.push(AppRoutes.savingsGoals),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Familia'),
          AppCard(
            child: Column(
              children: [
                _navTile(
                  context,
                  Icons.groups_2_outlined,
                  'Gestión familiar',
                  '',
                  onTap: () => context.push(AppRoutes.family),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Seguridad'),
          AppCard(
            child: Column(
              children: [
                _switchTile(
                  context,
                  Icons.fingerprint_rounded,
                  'Desbloqueo biométrico',
                  biometrics,
                  (v) async {
                    await ref
                        .read(securityRepositoryProvider)
                        .setBiometricsEnabled(v);
                    ref.read(biometricsEnabledProvider.notifier).state = v;
                    ref.invalidate(securityEventsProvider);
                  },
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.lock_outline_rounded,
                  'Cambiar contraseña',
                  '',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.admin_panel_settings_outlined,
                  'Seguridad y auditoría',
                  '',
                  onTap: () => context.push(AppRoutes.security),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Notificaciones'),
          AppCard(
            child: Column(
              children: [
                _switchTile(
                  context,
                  Icons.notifications_outlined,
                  'Notificaciones push',
                  _pushNotifications,
                  _savingNotifications
                      ? (_) {}
                      : (v) => _saveNotifications(v, _weeklySummary),
                ),
                const Divider(height: AppSpacing.lg),
                _switchTile(
                  context,
                  Icons.summarize_outlined,
                  'Resumen semanal',
                  _weeklySummary,
                  _savingNotifications
                      ? (_) {}
                      : (v) => _saveNotifications(_pushNotifications, v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Privacidad y datos'),
          AppCard(
            child: Column(
              children: [
                _navTile(
                  context,
                  Icons.privacy_tip_outlined,
                  'Política de privacidad',
                  '',
                  onTap: () => _showLegal(
                    context,
                    'Política de privacidad del piloto',
                    'La aplicación procesa datos financieros y métricas de uso exclusivamente para la evaluación académica. '
                        'Durante la etapa mock los datos financieros permanecen en memoria. Los comentarios y encuestas se guardan localmente hasta su integración segura con el backend. '
                        'No se realizan transferencias bancarias ni se venden datos personales.',
                  ),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.download_outlined,
                  'Exportaciones',
                  '',
                  onTap: () => context.push(AppRoutes.export),
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.science_outlined,
                  'Centro del piloto',
                  '',
                  onTap: () => context.push(AppRoutes.pilot),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionLabel(context, 'Acerca de'),
          AppCard(
            child: Column(
              children: [
                _navTile(
                  context,
                  Icons.info_outline_rounded,
                  'Versión',
                  '0.1.0',
                ),
                const Divider(height: AppSpacing.lg),
                _navTile(
                  context,
                  Icons.description_outlined,
                  'Términos y condiciones',
                  '',
                  onTap: () => _showLegal(
                    context,
                    'Términos de la prueba piloto',
                    'Esta versión es un prototipo académico. Los saldos y proyecciones no constituyen asesoramiento financiero. '
                        'La caja familiar es una representación lógica y no mueve dinero real. El participante puede retirarse de la evaluación cuando lo desee.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          color: context.colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _saveNotifications(bool push, bool weekly) async {
    final previousPush = _pushNotifications;
    final previousWeekly = _weeklySummary;
    setState(() {
      _pushNotifications = push;
      _weeklySummary = weekly;
      _savingNotifications = true;
    });
    try {
      if (push && push != previousPush) {
        final available = await ref
            .read(pushNotificationServiceProvider)
            .setEnabled(true);
        if (!available) {
          throw StateError('Las notificaciones no están disponibles.');
        }
      }
      await ref
          .read(notificationRepositoryProvider)
          .updatePreferences(pushEnabled: push, weeklySummary: weekly);
      if (!push && push != previousPush) {
        await ref.read(pushNotificationServiceProvider).setEnabled(false);
      }
      ref.invalidate(notificationPreferencesProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pushNotifications = previousPush;
        _weeklySummary = previousWeekly;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar las preferencias.')),
      );
    } finally {
      if (mounted) setState(() => _savingNotifications = false);
    }
  }

  void _showLegal(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    BuildContext context,
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _navTile(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            ),
          ),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 18),
        ],
      ),
    );
  }
}

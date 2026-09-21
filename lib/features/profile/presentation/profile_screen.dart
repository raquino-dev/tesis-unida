import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../app/theme/theme_mode_provider.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/offline/offline_runtime.dart';
import '../../../core/errors/app_failure.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/domain/user_alias_policy.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../auth/presentation/viewmodels/delete_account_viewmodel.dart';
import '../../subscription/presentation/subscription_viewmodel.dart';
import '../../security/presentation/widgets/otp_verification_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final subscriptionState = ref.watch(subscriptionViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            elevation: AppCardElevation.elevated,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (user?.name.trim().isNotEmpty == true
                            ? user!.name.trim()
                            : 'U')
                        .substring(0, 1),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Usuario',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.formattedAlias ?? '',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar nombre y alias',
                  onPressed: user == null
                      ? null
                      : () => _openEditProfileSheet(context, user),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.push(AppRoutes.subscription),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Suscripción',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                subscriptionState.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_) => const SizedBox.shrink(),
                  empty: () => const SizedBox.shrink(),
                  success: (s) => const AppBadge(
                    label: 'Ver planes',
                    tone: AppBadgeTone.premium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Preferencias',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _row(
                  context,
                  Icons.attach_money_rounded,
                  'Moneda base',
                  user?.currency ?? 'PYG',
                ),
                const Divider(height: AppSpacing.lg),
                _row(
                  context,
                  Icons.language_rounded,
                  'Idioma',
                  user?.language ?? 'Español',
                ),
                const Divider(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(
                      Icons.dark_mode_outlined,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Modo oscuro',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.push(AppRoutes.settings),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Configuración',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () async {
              if (await OfflineRuntime.instance.hasPendingOperations()) {
                if (!context.mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Hay información pendiente de guardar'),
                    content: const Text(
                      'Conectate a internet antes de cerrar sesión para conservar toda tu información. Si continuás ahora, los datos pendientes de este dispositivo se eliminarán.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Cerrar de todos modos'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
              }
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: Row(
              children: [
                Icon(Icons.logout_rounded, color: colors.error),
                const SizedBox(width: 10),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () => _openDeleteAccountSheet(context),
            child: Row(
              children: [
                Icon(Icons.delete_forever_outlined, color: colors.error),
                const SizedBox(width: 10),
                Text(
                  'Eliminar cuenta',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDeleteAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }

  void _openEditProfileSheet(BuildContext context, UserEntity user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value) {
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
        Text(
          value,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserEntity user;

  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _alias;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _alias = TextEditingController(text: widget.user.alias);
  }

  @override
  void dispose() {
    _name.dispose();
    _alias.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final aliasError = UserAliasPolicy.validate(_alias.text);
    if (name.isEmpty) {
      setState(() => _error = 'Ingresá tu nombre visible.');
      return;
    }
    if (aliasError != null) {
      setState(() => _error = aliasError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(currentUserProvider.notifier)
          .updateProfile(
            name: name,
            alias: UserAliasPolicy.normalize(_alias.text),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu perfil fue actualizado.')),
      );
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'No pudimos actualizar tu perfil. Intentá nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar perfil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'El nombre visible puede repetirse. El alias identifica únicamente tu cuenta.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Nombre visible',
                controller: _name,
                hint: 'Ej.: Rodrigo',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Alias único',
                controller: _alias,
                hint: '@Rodrigo001',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                UserAliasPolicy.requirements,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Guardar cambios',
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(deleteAccountViewModelProvider);

    ref.listen(deleteAccountViewModelProvider, (previous, next) {
      next.when(
        loading: () {},
        empty: () {},
        error: (_) {},
        success: (_) {
          Navigator.of(context).pop();
          context.go(AppRoutes.login);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tu cuenta fue eliminada. Esperamos verte de nuevo pronto.',
              ),
            ),
          );
        },
      );
    });

    final loading = state.when(
      loading: () => true,
      success: (_) => false,
      error: (_) => false,
      empty: () => false,
    );
    final errorMessage = state.when(
      loading: () => null,
      success: (_) => null,
      error: (m) => m,
      empty: () => null,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.error),
                const SizedBox(width: 8),
                Text(
                  'Eliminar tu cuenta',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta acción es irreversible. Se eliminarán tus movimientos, comprobantes, cuentas y presupuestos. '
              'Si sos propietario de un grupo familiar con otros integrantes, primero transferí la propiedad o eliminá el grupo.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirmá tu contraseña',
              controller: _password,
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Checkbox(
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'Entiendo que esta acción no se puede deshacer.',
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                errorMessage,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Eliminar mi cuenta',
              variant: AppButtonVariant.danger,
              isLoading: loading,
              onPressed: !_acknowledged || _password.text.isEmpty
                  ? null
                  : () async {
                      final verificationId = await requestOtpVerification(
                        context,
                        ref,
                        reason: 'Eliminar cuenta',
                      );
                      if (verificationId != null) {
                        await ref
                            .read(deleteAccountViewModelProvider.notifier)
                            .deleteAccount(
                              _password.text,
                              otpVerificationId: verificationId,
                            );
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

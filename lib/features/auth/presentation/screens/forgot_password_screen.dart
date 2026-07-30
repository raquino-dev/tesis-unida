import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/password_recovery_viewmodel.dart';
import '../../../../app/router/app_routes.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(passwordRecoveryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            empty: () => _form(colors, null),
            error: (message) => _form(colors, message),
            success: (email) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: colors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Revisá tu correo',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Te enviamos instrucciones para restablecer tu contraseña a $email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Ingresar código de recuperación',
                  onPressed: () => context.push(
                    '${AppRoutes.resetPassword}?token=RECUPERA-123',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(dynamic colors, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresá tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'Correo electrónico',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: TextStyle(color: colors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Enviar instrucciones',
          onPressed: () => ref
              .read(passwordRecoveryViewModelProvider.notifier)
              .sendRecovery(_email.text.trim()),
        ),
      ],
    );
  }
}

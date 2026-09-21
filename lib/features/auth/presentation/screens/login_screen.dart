import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/finanza_mark.dart';
import '../viewmodels/login_viewmodel.dart';
import '../../../security/presentation/widgets/otp_verification_dialog.dart';
import '../../../../core/config/app_environment.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _rememberSession = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(loginViewModelProvider);

    ref.listen(loginViewModelProvider, (previous, next) {
      next.when(
        loading: () {},
        empty: () {},
        error: (_) {},
        success: (_) => context.go(AppRoutes.dashboard),
      );
    });

    final errorMessage = state.when(
      loading: () => null,
      success: (_) => null,
      error: (m) => m,
      empty: () => null,
    );
    final loading = state.when(
      loading: () => true,
      success: (_) => false,
      error: (_) => false,
      empty: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FinanzaWordmark(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bienvenido de nuevo',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Iniciá sesión para continuar controlando tus finanzas.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                label: 'Correo electrónico',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Contraseña',
                controller: _password,
                obscureText: true,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  errorMessage,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _rememberSession,
                        onChanged: (v) => setState(() => _rememberSession = v),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recordar sesión',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: const Text('Olvidé mi contraseña'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Iniciar sesión',
                isLoading: loading,
                onPressed: () async {
                  if (!_rememberSession && !AppEnvironment.useApi) {
                    final verificationId = await requestOtpVerification(
                      context,
                      ref,
                      reason: 'Acceso desde dispositivo no habitual',
                    );
                    if (verificationId == null) return;
                  }
                  await ref
                      .read(loginViewModelProvider.notifier)
                      .login(
                        email: _email.text.trim(),
                        password: _password.text,
                        rememberSession: _rememberSession,
                      );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.register),
                  child: const Text('¿No tenés cuenta? Registrate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

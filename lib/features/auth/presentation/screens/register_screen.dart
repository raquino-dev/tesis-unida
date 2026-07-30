import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/register_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(registerViewModelProvider);

    ref.listen(registerViewModelProvider, (previous, next) {
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrate para empezar a controlar tus finanzas hoy mismo.',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(label: 'Nombre', controller: _name),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirmar contraseña',
                controller: _confirm,
                obscureText: true,
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
                label: 'Crear cuenta',
                isLoading: loading,
                onPressed: () => ref
                    .read(registerViewModelProvider.notifier)
                    .register(
                      name: _name.text.trim(),
                      email: _email.text.trim(),
                      password: _password.text,
                      confirmPassword: _confirm.text,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

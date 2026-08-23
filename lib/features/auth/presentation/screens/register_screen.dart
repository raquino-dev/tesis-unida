import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/register_viewmodel.dart';
import '../../domain/password_policy.dart';
import '../../domain/user_alias_policy.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _alias = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptsTerms = false;

  String? get _passwordError {
    if (_password.text.isEmpty) return null;
    return PasswordPolicy.validate(
      password: _password.text,
      email: _email.text,
      name: _name.text,
    );
  }

  String? get _aliasError {
    if (_alias.text.isEmpty) return null;
    return UserAliasPolicy.validate(_alias.text);
  }

  String? get _confirmationError {
    if (_confirm.text.isEmpty || _password.text == _confirm.text) return null;
    return 'Las contraseñas no coinciden.';
  }

  void _refreshValidation(String _) => setState(() {});

  @override
  void dispose() {
    _name.dispose();
    _alias.dispose();
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
              AppTextField(
                label: 'Nombre visible',
                hint: 'Ej.: Rodrigo',
                controller: _name,
                onChanged: _refreshValidation,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Alias único',
                hint: '@Rodrigo001',
                controller: _alias,
                errorText: _aliasError,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                onChanged: _refreshValidation,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                UserAliasPolicy.requirements,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Correo electrónico',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onChanged: _refreshValidation,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Contraseña',
                controller: _password,
                obscureText: true,
                errorText: _passwordError,
                onChanged: _refreshValidation,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                PasswordPolicy.requirements,
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Confirmar contraseña',
                controller: _confirm,
                obscureText: true,
                errorText: _confirmationError,
                onChanged: _refreshValidation,
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptsTerms,
                onChanged: (value) =>
                    setState(() => _acceptsTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Acepto los ', style: TextStyle(fontSize: 13)),
                    TextButton(
                      onPressed: () => _showLegalDocument(
                        context,
                        title: 'Términos y condiciones',
                        content: _termsAndConditions,
                      ),
                      child: const Text('términos y condiciones'),
                    ),
                    const Text(' y la ', style: TextStyle(fontSize: 13)),
                    TextButton(
                      onPressed: () => _showLegalDocument(
                        context,
                        title: 'Política de privacidad',
                        content: _privacyPolicy,
                      ),
                      child: const Text('política de privacidad.'),
                    ),
                  ],
                ),
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
                      alias: _alias.text.trim(),
                      email: _email.text.trim(),
                      password: _password.text,
                      confirmPassword: _confirm.text,
                      acceptsTerms: _acceptsTerms,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLegalDocument(
    BuildContext context, {
    required String title,
    required String content,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Flexible(child: SingleChildScrollView(child: Text(content))),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Entendido',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );

  static const _termsAndConditions =
      'Finanzas Inteligentes es un prototipo académico para una prueba piloto. '
      'No constituye asesoramiento financiero ni realiza transferencias de dinero reales. '
      'Las funcionalidades de presupuesto, proyección, suscripciones y comprobantes '
      'se utilizan únicamente para la evaluación descrita en la tesis. Podés dejar de '
      'usar la aplicación y solicitar la eliminación de tu perfil en cualquier momento.';

  static const _privacyPolicy =
      'La aplicación procesa los datos necesarios para brindar las funcionalidades '
      'del piloto y para evaluar facilidad de uso, utilidad y seguridad. Los datos no '
      'se venden ni se comparten con fines comerciales. Se aplican medidas de acceso '
      'autenticado, auditoría y minimización de datos. Podés consultar o solicitar la '
      'eliminación de tus datos contactando al investigador.';
}

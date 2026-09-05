import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/password_policy.dart';
import '../providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? initialToken;
  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _token = TextEditingController(text: widget.initialToken ?? '');
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _error;

  String? get _tokenError {
    if (_token.text.isEmpty) return null;
    if (AppEnvironment.useApi && _token.text.trim().length < 16) {
      return 'El código ingresado no parece válido.';
    }
    return null;
  }

  String? get _passwordError {
    if (_password.text.isEmpty) return null;
    return PasswordPolicy.validate(
      password: _password.text,
      email: '',
      name: '',
    );
  }

  String? get _confirmationError {
    if (_confirmation.text.isEmpty || _password.text == _confirmation.text) {
      return null;
    }
    return 'Las contraseñas no coinciden.';
  }

  void _refreshValidation(String _) => setState(() {});

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Ingresá el código recibido por correo.');
      return;
    }
    if (_tokenError != null) {
      setState(() => _error = _tokenError);
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Ingresá una contraseña nueva.');
      return;
    }
    if (_passwordError != null) {
      setState(() => _error = _passwordError);
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(token: token, newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida. Ya podés iniciar sesión.'),
        ),
      );
      context.go(AppRoutes.login);
    } on AppFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No pudimos restablecer la contraseña. Intentá nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            AppEnvironment.useApi
                ? 'Ingresá el código recibido por correo y elegí una contraseña nueva.'
                : 'Ingresá el código recibido por correo y elegí una contraseña nueva. En el prototipo podés usar RECUPERA-123.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Código de recuperación',
            hint: 'Pegá el código recibido por correo',
            controller: _token,
            errorText: _tokenError,
            onChanged: _refreshValidation,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nueva contraseña',
            controller: _password,
            obscureText: true,
            errorText: _passwordError,
            onChanged: _refreshValidation,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            PasswordPolicy.requirements,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmar contraseña',
            controller: _confirmation,
            obscureText: true,
            errorText: _confirmationError,
            onChanged: _refreshValidation,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Guardar contraseña',
            isLoading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}

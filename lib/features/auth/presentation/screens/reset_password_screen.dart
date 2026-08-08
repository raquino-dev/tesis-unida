import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
          .resetPassword(token: _token.text, newPassword: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida. Ya podés iniciar sesión.'),
        ),
      );
      context.go(AppRoutes.login);
    } on AppFailure catch (error) {
      setState(() {
        _loading = false;
        _error = error.message;
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
          AppTextField(label: 'Código de recuperación', controller: _token),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nueva contraseña',
            controller: _password,
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Confirmar contraseña',
            controller: _confirmation,
            obscureText: true,
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

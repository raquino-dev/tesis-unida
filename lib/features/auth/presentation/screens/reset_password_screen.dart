import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final String? recoveryId;
  final String? initialCode;

  const ResetPasswordScreen({super.key, this.recoveryId, this.initialCode});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _error;

  String? get _codeError {
    if (_code.text.isEmpty) return null;
    if (_code.text.trim().length != 6) {
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
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (widget.recoveryId == null || widget.recoveryId!.isEmpty) {
      setState(
        () => _error =
            'Solicitá un nuevo código para continuar con la recuperación.',
      );
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'Ingresá el código recibido por correo.');
      return;
    }
    if (_codeError != null) {
      setState(() => _error = _codeError);
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
          .resetPassword(
            recoveryId: widget.recoveryId!,
            code: code,
            newPassword: _password.text,
          );
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

  Future<void> _pasteCode() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = clipboard?.text ?? '';
    final match = RegExp(r'(?<!\d)\d{6}(?!\d)').firstMatch(text);
    if (match == null) {
      setState(
        () => _error = 'El portapapeles no contiene un código de 6 dígitos.',
      );
      return;
    }
    _code.text = match.group(0)!;
    _code.selection = TextSelection.collapsed(offset: _code.text.length);
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              AppEnvironment.useApi
                  ? 'Ingresá el código recibido por correo y elegí una contraseña nueva.'
                  : 'Ingresá el código recibido por correo y elegí una contraseña nueva. En el prototipo podés usar 123456.',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Código de recuperación',
              hint: 'Código de 6 dígitos',
              controller: _code,
              errorText: _codeError,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                tooltip: 'Pegar código',
                onPressed: _pasteCode,
                icon: const Icon(Icons.content_paste_outlined),
              ),
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
      ),
    );
  }
}

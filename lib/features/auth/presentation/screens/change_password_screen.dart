import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../security/domain/security_entity.dart';
import '../../../security/presentation/security_providers.dart';
import '../../../security/presentation/widgets/otp_verification_dialog.dart';
import '../providers/auth_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text != _confirmation.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    final verified = await requestOtpVerification(
      context,
      ref,
      reason: 'Cambio de contraseña',
    );
    if (!verified || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      await ref
          .read(securityRepositoryProvider)
          .recordEvent(
            SecurityEventType.passwordChange,
            'Contraseña actualizada',
          );
      ref.invalidate(securityEventsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppTextField(
            label: 'Contraseña actual',
            controller: _current,
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nueva contraseña',
            controller: _next,
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
            label: 'Actualizar contraseña',
            isLoading: _loading,
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}

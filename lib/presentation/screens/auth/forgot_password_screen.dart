import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Enter a valid email address');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      setState(() => _errorMsg = 'Failed to send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _sent ? _buildSentView(context) : _buildFormView(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_outlined, size: 56, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Forgot your password?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your email and we'll send you a reset link.",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textSecondary),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 12),
          Text(_errorMsg!, style: const TextStyle(color: AppColors.alertUrgent, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Send Reset Link'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(Routes.login),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }

  Widget _buildSentView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 72, color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Check your inbox',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Password reset link sent to\n${_emailCtrl.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textSecondary),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go(Routes.login),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}

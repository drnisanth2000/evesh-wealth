import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/evesh_logo.dart';
import '../../widgets/forms/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final response = await ref.read(authNotifierProvider.notifier)
          .signInWithPassword(_emailCtrl.text.trim(), _passCtrl.text);

      if (!mounted) return;

      // Check if MFA is required
      if (response.session == null && response.user != null) {
        // MFA challenge needed
        context.push(Routes.mfaChallenge);
      } else {
        context.go(Routes.dashboard);
      }
    } on AuthException catch (e) {
      setState(() { _errorMsg = _friendlyError(e.message); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authNotifierProvider.notifier)
          .signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      setState(() { _errorMsg = 'Google sign-in failed. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ref.read(authNotifierProvider.notifier)
          .signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      setState(() { _errorMsg = 'Apple sign-in failed. Please try again.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (msg.contains('Too many requests')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (msg.contains('Failed to decode') ||
        msg.contains('empty response') ||
        msg.contains('FormatException')) {
      return 'Sign-in service is unreachable. Try a hard refresh '
          '(Cmd/Ctrl+Shift+R) or clear site data, then sign in again.';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host')) {
      return 'Network error. Check your connection and try again.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EVeshLogo(size: 56),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to your eVesh account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── OAuth buttons ────────────────────────────────────────────
                  _OAuthButton(
                    label: 'Continue with Google',
                    iconPath: 'assets/icons/google.svg',
                    onPressed: _loading ? null : _signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _OAuthButton(
                    label: 'Continue with Apple',
                    iconPath: 'assets/icons/apple.svg',
                    onPressed: _loading ? null : _signInWithApple,
                  ),

                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: context.palette.textSecondary)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),

                  // ── Email / password form ────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _passCtrl,
                          label: 'Password',
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _signIn(),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(Routes.forgotPassword),
                            child: const Text('Forgot password?'),
                          ),
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.alertUrgentBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.alertUrgent.withOpacity(0.4)),
                            ),
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(color: AppColors.alertUrgent, fontSize: 13),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loading ? null : _signIn,
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(color: context.palette.textSecondary)),
                      TextButton(
                        onPressed: () => context.push(Routes.signup),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Sign up free'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.iconPath,
    required this.onPressed,
  });

  final String label;
  final String iconPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.palette.textPrimary,
        side: BorderSide(color: context.palette.bgDivider),
        backgroundColor: context.palette.bgSurface,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple icon placeholder (replace with actual SVG icons)
          Icon(
            label.contains('Google') ? Icons.g_mobiledata : Icons.apple,
            size: 22,
            color: context.palette.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/evesh_logo.dart';

enum MfaMode { setup, challenge }

class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({super.key, required this.mode});
  final MfaMode mode;

  @override
  ConsumerState<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends ConsumerState<MfaScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;
  String? _qrCode;
  String? _factorId;
  String? _secret;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MfaMode.setup) _startEnrollment();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    setState(() => _loading = true);
    try {
      final response = await ref.read(authNotifierProvider.notifier).enrollMfa();
      setState(() {
        _factorId = response.id;
        _qrCode = response.totp?.qrCode;
        _secret = response.totp?.secret;
      });
    } catch (e) {
      setState(() => _errorMsg = 'Failed to start MFA setup. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _errorMsg = 'Enter the 6-digit code from your authenticator app');
      return;
    }
    if (_factorId == null && widget.mode == MfaMode.setup) {
      setState(() => _errorMsg = 'MFA enrollment not started');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });
    try {
      if (widget.mode == MfaMode.setup) {
        await ref.read(authNotifierProvider.notifier).verifyMfaChallenge(
          factorId: _factorId!,
          code: _codeCtrl.text,
        );
      } else {
        // Challenge mode: get factor ID from listed factors
        final factors = await ref.read(authNotifierProvider.notifier).listMfaFactors();
        final totp = factors.totp.firstOrNull;
        if (totp == null) {
          setState(() => _errorMsg = 'No MFA factor found. Please set up MFA first.');
          return;
        }
        await ref.read(authNotifierProvider.notifier).verifyMfaChallenge(
          factorId: totp.id,
          code: _codeCtrl.text,
        );
      }

      if (mounted) context.go(Routes.dashboard);
    } catch (e) {
      setState(() => _errorMsg = 'Invalid code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == MfaMode.setup ? 'Set Up 2FA' : 'Verify Identity'),
        leading: widget.mode == MfaMode.challenge
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(Routes.login),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading && widget.mode == MfaMode.setup && _qrCode == null
                  ? const CircularProgressIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const EVeshLogo(size: 48),
                        const SizedBox(height: 16),

                        if (widget.mode == MfaMode.setup) ...[
                          Text(
                            'Scan with Authenticator App',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use Google Authenticator, Authy, or any TOTP app',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.palette.textSecondary),
                          ),
                          const SizedBox(height: 24),

                          // QR Code display
                          if (_qrCode != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                // QR code as SVG/Image would be rendered here
                                // For now show the secret key as fallback
                                child: Column(
                                  children: [
                                    const Icon(Icons.qr_code_2, size: 120, color: Colors.black),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Manual entry key:',
                                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                                    ),
                                    SelectableText(
                                      _secret ?? '',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const Icon(Icons.lock_outline, size: 56, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Two-Factor Authentication',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit code from your authenticator app',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.palette.textSecondary),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 6-digit code input
                        TextFormField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Authentication Code',
                            counterText: '',
                            hintText: '000000',
                          ),
                          onChanged: (v) {
                            if (v.length == 6) _verify();
                          },
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.alertUrgentBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(color: AppColors.alertUrgent, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loading ? null : _verify,
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(widget.mode == MfaMode.setup ? 'Enable 2FA' : 'Verify'),
                        ),

                        if (widget.mode == MfaMode.setup) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go(Routes.dashboard),
                            child: const Text('Skip for now'),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

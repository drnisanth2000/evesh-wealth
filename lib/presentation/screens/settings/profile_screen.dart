import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.fullName ?? '';
      _panCtrl.text = profile.pan ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'pan': _panCtrl.text.trim().toUpperCase(),
      }).eq('id', userId);

      ref.invalidate(currentProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'),
              backgroundColor: AppColors.gain),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: AppColors.loss),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Full Name',
                style: TextStyle(
                    fontSize: 12, color: context.palette.textTertiary)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(hintText: 'Your full name'),
            ),
            const SizedBox(height: 16),
            Text('PAN Number',
                style: TextStyle(
                    fontSize: 12, color: context.palette.textTertiary)),
            const SizedBox(height: 6),
            TextField(
              controller: _panCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  hintText: 'ABCDE1234F',
                  helperText: 'Used for MF Central import matching'),
            ),
          ],
        ),
      ),
    );
  }
}

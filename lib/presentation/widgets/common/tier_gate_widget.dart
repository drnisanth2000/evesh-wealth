import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/family_provider.dart';
import '../../router/route_names.dart';

/// Wraps a child widget behind a subscription tier gate.
/// If [requiredTier] is not met, shows an upgrade prompt instead.
class TierGateWidget extends ConsumerWidget {
  const TierGateWidget({
    super.key,
    required this.child,
    required this.requiredTier,
    this.featureName,
  });

  final Widget child;
  final String requiredTier; // 'individual' | 'family'
  final String? featureName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;

    final hasAccess = _hasAccess(profile?.subscriptionTier ?? 'free');
    if (hasAccess) return child;

    return _UpgradePrompt(
      requiredTier: requiredTier,
      featureName: featureName ?? 'this feature',
    );
  }

  bool _hasAccess(String currentTier) {
    if (currentTier == 'family') return true;
    if (currentTier == 'individual' && requiredTier == 'individual') return true;
    return false;
  }
}

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({
    required this.requiredTier,
    required this.featureName,
  });

  final String requiredTier;
  final String featureName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_outlined,
                  size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to ${requiredTier[0].toUpperCase()}${requiredTier.substring(1)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Access $featureName and more with an upgraded plan.',
              style: TextStyle(
                  fontSize: 14, color: context.palette.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push(Routes.subscription),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('View Plans'),
            ),
          ],
        ),
      ),
    );
  }
}

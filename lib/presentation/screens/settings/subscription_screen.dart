import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/family_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final currentTier = profileAsync.valueOrNull?.subscriptionTier ?? 'free';

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current tier banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current plan: ${_tierLabel(currentTier)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),

          _PlanCard(
            title: 'Free',
            price: '₹0',
            period: 'forever',
            isCurrentPlan: currentTier == 'free',
            features: const [
              '1 family member',
              'Up to 50 transactions',
              'Mutual funds only',
              'Basic dashboard',
            ],
            unavailable: const [
              'MF Central upload',
              'What-If analysis',
              'Investment suggestions',
              'Full analytics',
              'Family consolidated view',
            ],
            onSelect: null,
          ),
          const SizedBox(height: 12),

          _PlanCard(
            title: 'Individual',
            price: '₹299',
            period: '/ month',
            isCurrentPlan: currentTier == 'individual',
            highlighted: true,
            features: const [
              '1 member',
              'Unlimited transactions',
              'All asset types',
              'MF Central upload',
              'What-If analysis',
              'Investment suggestions',
              'Full analytics (Sharpe, Sortino, etc.)',
            ],
            unavailable: const ['Family consolidated view'],
            onSelect: currentTier == 'individual'
                ? null
                : () => _handleUpgrade(context, 'individual'),
          ),
          const SizedBox(height: 12),

          _PlanCard(
            title: 'Family',
            price: '₹599',
            period: '/ month',
            isCurrentPlan: currentTier == 'family',
            features: const [
              'Unlimited family members',
              'Unlimited transactions',
              'All asset types',
              'MF Central upload',
              'What-If analysis',
              'Investment suggestions',
              'Full analytics',
              'Family consolidated view',
              'Member-wise tax breakdown',
            ],
            unavailable: const [],
            onSelect: currentTier == 'family'
                ? null
                : () => _handleUpgrade(context, 'family'),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Payments powered by Razorpay  •  Cancel anytime',
              style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'individual':
        return 'Individual';
      case 'family':
        return 'Family';
      default:
        return 'Free';
    }
  }

  void _handleUpgrade(BuildContext context, String tier) {
    // TODO: Integrate Razorpay checkout
    // For now show a placeholder dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Coming Soon'),
        content: Text(
          'Razorpay checkout will be integrated here. '
          'You will be charged for the $tier plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.unavailable,
    required this.isCurrentPlan,
    this.highlighted = false,
    this.onSelect,
  });

  final String title;
  final String price;
  final String period;
  final List<String> features;
  final List<String> unavailable;
  final bool isCurrentPlan;
  final bool highlighted;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withOpacity(0.5)
              : context.palette.bgDivider,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color:
                        highlighted ? AppColors.primary : context.palette.textPrimary,
                  )),
              if (highlighted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Popular',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  Text(period,
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Included features
          ...features.map((f) => _FeatureRow(label: f, included: true)),
          ...unavailable.map((f) => _FeatureRow(label: f, included: false)),

          const SizedBox(height: 16),

          // CTA
          SizedBox(
            width: double.infinity,
            child: isCurrentPlan
                ? OutlinedButton(
                    onPressed: null,
                    child: const Text('Current Plan'),
                  )
                : ElevatedButton(
                    onPressed: onSelect,
                    child: Text('Upgrade to $title'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.included});
  final String label;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: included ? AppColors.gain : context.palette.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: included ? context.palette.textPrimary : context.palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

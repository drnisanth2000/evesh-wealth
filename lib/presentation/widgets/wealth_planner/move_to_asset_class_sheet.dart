import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/asset_class_override_provider.dart';

/// Bottom sheet letting the user re-classify a fund into a different
/// [AssetClass]. Writes to `transactions.asset_class_override`.
///
/// Selecting a class writes the override; "Auto" clears it (returns null) so
/// the resolver falls back to AMFI category → asset class label → category.
class MoveToAssetClassSheet extends ConsumerWidget {
  const MoveToAssetClassSheet({
    super.key,
    required this.amfiCode,
    required this.title,
    this.currentAssetClass,
  });

  final int amfiCode;
  final String title;
  final AssetClass? currentAssetClass;

  static Future<void> show({
    required BuildContext context,
    required int amfiCode,
    required String title,
    AssetClass? currentAssetClass,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => MoveToAssetClassSheet(
        amfiCode: amfiCode,
        title: title,
        currentAssetClass: currentAssetClass,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Move to another asset class',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final cls in AssetClass.values)
              _AssetClassTile(
                assetClass: cls,
                isSelected: currentAssetClass == cls,
                onTap: () => _apply(context, ref, cls),
              ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Auto (clear override)'),
              subtitle: const Text('Use the auto-derived class from fund metadata.'),
              onTap: () => _apply(context, ref, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    AssetClass? assetClass,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(assetClassOverrideMutatorProvider.notifier)
          .setForFund(amfiCode: amfiCode, assetClass: assetClass);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
          assetClass == null
              ? 'Override cleared'
              : 'Moved to ${assetClass.displayName}',
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Move failed: $e')));
    }
  }
}

class _AssetClassTile extends StatelessWidget {
  const _AssetClassTile({
    required this.assetClass,
    required this.isSelected,
    required this.onTap,
  });

  final AssetClass assetClass;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(assetClass);
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_iconFor(assetClass), size: 16, color: color),
      ),
      title: Text(assetClass.displayName),
      trailing: isSelected ? Icon(Icons.check, color: color, size: 18) : null,
      onTap: onTap,
    );
  }

  Color _colorFor(AssetClass c) {
    switch (c) {
      case AssetClass.coreEquity:
        return const Color(0xFF2E7D32);
      case AssetClass.satelliteEquity:
        return const Color(0xFF43A047);
      case AssetClass.hybrid:
        return const Color(0xFF8E24AA);
      case AssetClass.debt:
        return const Color(0xFF6D4C41);
      case AssetClass.liquid:
        return const Color(0xFF1E88E5);
      case AssetClass.gold:
        return const Color(0xFFFFB300);
      case AssetClass.alternate:
        return const Color(0xFF546E7A);
    }
  }

  IconData _iconFor(AssetClass c) {
    switch (c) {
      case AssetClass.coreEquity:
        return Icons.show_chart;
      case AssetClass.satelliteEquity:
        return Icons.trending_up;
      case AssetClass.hybrid:
        return Icons.balance;
      case AssetClass.debt:
        return Icons.receipt_long;
      case AssetClass.liquid:
        return Icons.water_drop;
      case AssetClass.gold:
        return Icons.star;
      case AssetClass.alternate:
        return Icons.diversity_3;
    }
  }
}

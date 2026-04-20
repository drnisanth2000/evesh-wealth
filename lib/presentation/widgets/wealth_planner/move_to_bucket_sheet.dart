import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bucket_mapping.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/bucket_composition_provider.dart';

/// Bottom sheet letting the user pick a bucket override for a fund holding
/// (by AMFI code) or an other_assets row (by id). Pass exactly one of the two.
///
/// Selecting a [Bucket] writes the override; "Auto" clears it (returns null).
class MoveToBucketSheet extends ConsumerWidget {
  const MoveToBucketSheet({
    super.key,
    this.amfiCode,
    this.otherAssetId,
    required this.title,
    this.currentBucket,
  });

  final int? amfiCode;
  final String? otherAssetId;
  final String title;
  final Bucket? currentBucket;

  static Future<void> show({
    required BuildContext context,
    int? amfiCode,
    String? otherAssetId,
    required String title,
    Bucket? currentBucket,
  }) {
    assert((amfiCode == null) ^ (otherAssetId == null),
        'Pass exactly one of amfiCode or otherAssetId');
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => MoveToBucketSheet(
        amfiCode: amfiCode,
        otherAssetId: otherAssetId,
        title: title,
        currentBucket: currentBucket,
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
              'Move to bucket',
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
            for (final b in Bucket.values)
              _BucketTile(
                bucket: b,
                isSelected: currentBucket == b,
                onTap: () => _apply(context, ref, b),
              ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Auto (clear override)'),
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
    Bucket? bucket,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final mutator = ref.read(bucketOverrideMutatorProvider.notifier);
      if (amfiCode != null) {
        await mutator.setForFund(amfiCode: amfiCode!, bucket: bucket);
      } else if (otherAssetId != null) {
        await mutator.setForOtherAsset(id: otherAssetId!, bucket: bucket);
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
          bucket == null
              ? 'Override cleared'
              : 'Moved to ${bucket.displayName}',
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Move failed: $e')));
    }
  }
}

class _BucketTile extends StatelessWidget {
  const _BucketTile({
    required this.bucket,
    required this.isSelected,
    required this.onTap,
  });

  final Bucket bucket;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bucket.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(bucket.icon, size: 16, color: bucket.color),
      ),
      title: Text(bucket.displayName),
      trailing: isSelected
          ? Icon(Icons.check, color: bucket.color, size: 18)
          : null,
      onTap: onTap,
    );
  }
}

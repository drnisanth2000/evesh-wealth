import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/usecases/run_rebalance_analysis.dart';
import '../../providers/rebalance_provider.dart';
import '../../widgets/common/section_header.dart';

class RebalanceScreen extends ConsumerWidget {
  const RebalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rebalanceAsync = ref.watch(rebalanceAnalysisProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebalancing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(rebalanceAnalysisProvider(null)),
          ),
        ],
      ),
      body: rebalanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(rebalanceAnalysisProvider(null)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 3-bucket summary ──────────────────────────────────────
              SectionHeader(title: '3-Bucket Allocation'),
              ...result.bucketAllocations.map((b) => _BucketCard(bucket: b)),

              const SizedBox(height: 20),

              // ── Per-asset drift ───────────────────────────────────────
              SectionHeader(title: 'Asset Class Drift'),
              ...result.allocationDrifts.map((d) => _DriftRow(
                    drift: d,
                    threshold: result.driftThreshold,
                  )),

              const SizedBox(height: 20),

              // ── Suggestions ───────────────────────────────────────────
              if (result.topFundSuggestions.isNotEmpty) ...[
                SectionHeader(title: 'Recommended Moves'),
                ...result.topFundSuggestions.map(
                    (s) => _SuggestionTile(s: s)),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.gain.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: context.palette.gain.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: context.palette.gain),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Portfolio is well-balanced! '
                          'All asset classes within ${result.driftThreshold.toStringAsFixed(0)}% of target.',
                          style: TextStyle(
                              color: context.palette.textSecondary,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  const _BucketCard({required this.bucket});
  final BucketAllocation bucket;

  @override
  Widget build(BuildContext context) {
    final colors = [context.palette.gain, AppColors.info, AppColors.primary];
    final color = colors[(bucket.bucketNumber - 1).clamp(0, 2)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(bucket.bucketName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text(bucket.currentValue.toINRCompact(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${bucket.currentPct.toStringAsFixed(1)}% of portfolio  •  '
            'Target: ${bucket.targetPct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 12, color: context.palette.textTertiary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (bucket.currentPct / 100).clamp(0.0, 1.0),
              backgroundColor: context.palette.bgDivider,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriftRow extends StatelessWidget {
  const _DriftRow({required this.drift, required this.threshold});
  final AllocationDrift drift;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final isOver = drift.driftPct > 0;
    final isWithin = drift.driftPct.abs() <= threshold;
    final driftColor = isWithin
        ? context.palette.gain
        : isOver
            ? context.palette.loss
            : AppColors.info;
    final trafficLight = isWithin
        ? Icons.circle
        : isOver
            ? Icons.arrow_upward
            : Icons.arrow_downward;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(trafficLight, size: 14, color: driftColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(drift.assetClass.displayName,
                style: const TextStyle(fontSize: 14)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${drift.currentPct.toStringAsFixed(1)}% / ${drift.targetPct.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 12, color: context.palette.textSecondary),
              ),
              Text(
                '${isOver ? '+' : ''}${drift.driftPct.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: driftColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.s});
  final FundRebalanceSuggestion s;

  @override
  Widget build(BuildContext context) {
    final isAdd = s.suggestedAction == RebalanceAction.add;
    final color = isAdd ? context.palette.gain : context.palette.loss;
    final icon = isAdd
        ? Icons.add_circle_outline
        : Icons.remove_circle_outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(s.fundName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '${s.assetClass.displayName}  •  ${isAdd ? 'Add' : 'Reduce'} ${s.suggestedAmount.toINRCompact()}',
          style: TextStyle(
              fontSize: 12, color: context.palette.textSecondary),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isAdd ? 'Add' : 'Reduce',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

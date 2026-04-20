import 'package:flutter/material.dart';

import '../../../core/constants/bucket_mapping.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/other_asset_model.dart';
import '../../providers/bucket_composition_provider.dart';
import '../../providers/pending_moves_provider.dart';
import 'move_to_bucket_sheet.dart';

/// One-liner tip per bucket.
const _bucketTips = <Bucket, String>{
  Bucket.liquid: 'Emergency cash, horizon <= 6 months',
  Bucket.fixedIncome: 'Capital preservation with predictable yield',
  Bucket.growth: 'Long-horizon equity-like risk',
};

/// Renders one bucket as a card with header, progress bar, knowledge tip,
/// optional alerts, fund holdings, other assets, and (when pending moves
/// exist) faint-text arrival rows for funds being routed into this bucket.
class BucketCompositionCard extends StatelessWidget {
  const BucketCompositionCard({
    super.key,
    required this.bc,
    this.arrivals = const [],
    this.onMoveFund,
  });

  final BucketComposition bc;
  final List<PendingMove> arrivals;
  final void Function(int amfiCode)? onMoveFund;

  _StatusTone get _tone {
    final abs = bc.gapPct.abs();
    if (abs < 2) return _StatusTone.onTarget;
    if (abs < 5) return _StatusTone.watch;
    return _StatusTone.drift;
  }

  Color _statusColor() {
    switch (_tone) {
      case _StatusTone.onTarget:
        return AppColors.gain;
      case _StatusTone.watch:
        return AppColors.warning;
      case _StatusTone.drift:
        return bc.gapPct > 0 ? AppColors.loss : AppColors.info;
    }
  }

  String _statusLabel() {
    if (_tone == _StatusTone.onTarget) return 'On target';
    final sign = bc.gapPct > 0 ? 'Over' : 'Under';
    return '$sign by ${bc.gapPct.abs().toStringAsFixed(1)}pp';
  }

  @override
  Widget build(BuildContext context) {
    final bucket = bc.bucket;
    final showAlerts = bc.goalAlerts.isNotEmpty || bc.gapPct.abs() > 15;
    final statusColor = _statusColor();
    // LinearProgressIndicator max is 1.0. Scale so target % sits at half-bar
    // and drift either side reads instantly: 0% → 0.0, target% → 0.5, 2×target → 1.0.
    final ratio =
        bc.targetPct == 0 ? 0.0 : (bc.currentPct / bc.targetPct).clamp(0.0, 2.0);
    final displayProgress = (ratio / 2).clamp(0.0, 1.0);

    return Card(
      color: context.palette.bgCard,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: bucket.color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar keyed to bucket color for instant visual anchor.
              Container(
                width: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: bucket.color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(bc: bc, statusColor: statusColor, statusLabel: _statusLabel()),
                    const SizedBox(height: 10),
                    _ProgressRow(
                      bc: bc,
                      color: statusColor,
                      displayProgress: displayProgress,
                    ),
                    const SizedBox(height: 10),
                    _KnowledgeTip(bucket: bucket),
                    if (showAlerts) ...[
                      const SizedBox(height: 10),
                      _AlertsCard(bc: bc),
                    ],
                    if (bc.funds.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const _SectionHeader(label: 'Mutual Fund Holdings'),
                      const SizedBox(height: 4),
                      for (final line in bc.funds)
                        _FundRow(line: line, onMoveFund: onMoveFund),
                    ],
                    if (bc.otherAssets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const _SectionHeader(label: 'Other Assets'),
                      const SizedBox(height: 4),
                      for (final line in bc.otherAssets)
                        _OtherAssetRow(line: line),
                    ],
                    if (bc.funds.isEmpty && bc.otherAssets.isEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'No holdings in this bucket yet.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textTertiary,
                        ),
                      ),
                    ],
                    if (arrivals.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ArrivalsSection(bucket: bucket, arrivals: arrivals),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StatusTone { onTarget, watch, drift }

class _Header extends StatelessWidget {
  const _Header({
    required this.bc,
    required this.statusColor,
    required this.statusLabel,
  });
  final BucketComposition bc;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final bucket = bc.bucket;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bucket.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(bucket.icon, size: 16, color: bucket.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bucket.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              Text(
                '${bc.funds.length + bc.otherAssets.length} '
                'holding${(bc.funds.length + bc.otherAssets.length) == 1 ? '' : 's'} · '
                '${bc.currentValue.toINR(compact: true)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.bc,
    required this.color,
    required this.displayProgress,
  });
  final BucketComposition bc;
  final Color color;
  final double displayProgress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: displayProgress,
                minHeight: 8,
                backgroundColor: palette.bgDivider,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            // Target marker at 50% of the bar (representing targetPct).
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: LayoutBuilder(builder: (_, c) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: c.maxWidth * 0.5 - 1),
                    child: Container(
                      width: 2,
                      color: palette.textTertiary.withValues(alpha: 0.6),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Current ${bc.currentPct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              'Target ${bc.targetPct.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _KnowledgeTip extends StatelessWidget {
  const _KnowledgeTip({required this.bucket});
  final Bucket bucket;

  @override
  Widget build(BuildContext context) {
    final tip = _bucketTips[bucket] ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 12, color: AppColors.info),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.bc});
  final BucketComposition bc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber,
                  size: 12, color: AppColors.warning),
              SizedBox(width: 6),
              Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (bc.gapPct.abs() > 15)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                bc.gapPct > 0
                    ? 'Over target by ${bc.gapPct.toStringAsFixed(1)}%'
                    : 'Under target by ${bc.gapPct.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          for (final a in bc.goalAlerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${a.goalName} approaches in ${a.monthsAway} mo — consider '
                'moving ${a.fundName} to Liquid',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: context.palette.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FundRow extends StatelessWidget {
  const _FundRow({required this.line, required this.onMoveFund});
  final HoldingLine line;
  final void Function(int amfiCode)? onMoveFund;

  @override
  Widget build(BuildContext context) {
    final h = line.holding;
    final assetLabel = h.assetClassLabel ?? h.category ?? 'Asset';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.fundName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Chip(label: assetLabel),
                    if (line.isOverridden) ...[
                      const SizedBox(width: 4),
                      const _Chip(label: 'Override'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            h.currentValue.toINR(compact: true),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 16, color: context.palette.textTertiary),
            onSelected: (v) {
              if (v == 'move') {
                if (onMoveFund != null) {
                  onMoveFund!.call(h.amfiCode);
                } else {
                  MoveToBucketSheet.show(
                    context: context,
                    amfiCode: h.amfiCode,
                    title: h.fundName,
                    currentBucket: line.effectiveBucket,
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'move',
                child: Text('Move to bucket'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtherAssetRow extends StatelessWidget {
  const _OtherAssetRow({required this.line});
  final OtherAssetLine line;

  @override
  Widget build(BuildContext context) {
    final a = line.asset;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _Chip(label: a.assetType),
              ],
            ),
          ),
          Text(
            a.effectiveValue.toINR(compact: true),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivalsSection extends StatelessWidget {
  const _ArrivalsSection({required this.bucket, required this.arrivals});
  final Bucket bucket;
  final List<PendingMove> arrivals;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bucket.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bucket.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_land, size: 12, color: palette.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Arriving from pending moves',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...arrivals.map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.toFundName.isEmpty
                            ? '(choose fund) · from ${m.fromFundName}'
                            : '${m.toFundName}  ← ${m.fromFundName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      '+${m.amount.toINR(compact: true)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}

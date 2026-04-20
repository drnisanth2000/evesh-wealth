import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/asset_class_resolver.dart';
import '../../../../core/constants/asset_classes.dart';
import '../../../../core/constants/bucket_mapping.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/goal_model.dart';
import '../../../../data/models/portfolio_summary_model.dart';
// `BucketComposition` is also defined in simulation_models — hide the
// duplicate so the provider-layer class stays the one the UI resolves.
import '../../../../domain/models/simulation_models.dart' show SimulationState;
import '../../../../domain/usecases/compute_goal_bucket_target.dart';
import '../../../providers/bucket_composition_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/pending_moves_provider.dart';
import '../../../providers/portfolio_provider.dart';
import '../../../providers/selected_goal_filter_provider.dart';
import '../../../providers/selected_member_provider.dart';
import '../../../providers/simulation_provider.dart';
import '../../../providers/wealth_planner_provider.dart';
import '../../../widgets/wealth_planner/bucket_composition_card.dart';

/// Bucket sub-tab. Renders:
///   1. A horizontal strip of three **vertically-elongated bucket silhouettes**
///      — each shows current fill level vs target (dashed tick line).
///   2. A single [BucketCompositionCard] below for the currently selected
///      bucket. Tap a silhouette → swap the detail card.
///
/// Defaults to Liquid selected. Honors `selectedGoalFilterProvider`: when a
/// goal is picked from the Plan tab, the strip + card are scoped to the
/// goal's linked funds + term-based target mix.
class AllocBucketTab extends ConsumerStatefulWidget {
  const AllocBucketTab({super.key});

  @override
  ConsumerState<AllocBucketTab> createState() => _AllocBucketTabState();
}

class _AllocBucketTabState extends ConsumerState<AllocBucketTab> {
  Bucket _selected = Bucket.liquid;

  @override
  Widget build(BuildContext context) {
    final memberId = ref.watch(selectedMemberProvider);
    final filterGoalId = ref.watch(selectedGoalFilterProvider);
    final arrivals = ref.watch(arrivalsByBucketProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bucketCompositionProvider(memberId));
        ref.invalidate(portfolioSummaryProvider(memberId));
      },
      child: filterGoalId == null
          ? _PortfolioBody(
              memberId: memberId,
              arrivals: arrivals,
              selected: _selected,
              onSelect: (b) => setState(() => _selected = b),
            )
          : _GoalScopedBody(
              memberId: memberId,
              goalId: filterGoalId,
              arrivals: arrivals,
              selected: _selected,
              onSelect: (b) => setState(() => _selected = b),
            ),
    );
  }
}

// ─── Portfolio body ────────────────────────────────────────────────────────

class _PortfolioBody extends ConsumerWidget {
  const _PortfolioBody({
    required this.memberId,
    required this.arrivals,
    required this.selected,
    required this.onSelect,
  });

  final String? memberId;
  final Map<Bucket, List<PendingMove>> arrivals;
  final Bucket selected;
  final ValueChanged<Bucket> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(bucketCompositionProvider(memberId));
    return compAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _error(context, e),
      data: (result) => _bucketLayout(
        memberId: memberId,
        result: result,
        arrivals: arrivals,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }
}

// ─── Goal-scoped body ──────────────────────────────────────────────────────

class _GoalScopedBody extends ConsumerWidget {
  const _GoalScopedBody({
    required this.memberId,
    required this.goalId,
    required this.arrivals,
    required this.selected,
    required this.onSelect,
  });

  final String? memberId;
  final String goalId;
  final Map<Bucket, List<PendingMove>> arrivals;
  final Bucket selected;
  final ValueChanged<Bucket> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final linksAsync = ref.watch(goalFundLinksProvider);
    final portfolioAsync = ref.watch(portfolioSummaryProvider(memberId));
    final healthAsync = ref.watch(allocationHealthProvider(memberId));

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _error(context, e),
      data: (goals) => linksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error(context, e),
        data: (links) => portfolioAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _error(context, e),
          data: (portfolio) => healthAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _error(context, e),
            data: (health) {
              final match = goals.where((g) => g.id == goalId).toList();
              if (match.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Goal no longer exists.'),
                );
              }
              final scopedGoals = memberId == null
                  ? goals.where((g) => g.memberId == null).toList()
                  : goals.where((g) => g.memberId == memberId).toList();
              final result = _buildGoalComposition(
                goal: match.first,
                goalsInScope: scopedGoals,
                links: links,
                holdings: portfolio.fundHoldings,
                ideal: health.idealAllocation,
                autoAttach: memberId != null,
              );
              return Column(
                children: [
                  _GoalBanner(goal: match.first),
                  Expanded(
                    child: _bucketLayout(
                      memberId: memberId,
                      result: result,
                      arrivals: arrivals,
                      selected: selected,
                      onSelect: onSelect,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Shared layout: strip + editor + single detail card ──────────────────

Widget _bucketLayout({
  required String? memberId,
  required BucketCompositionResult result,
  required Map<Bucket, List<PendingMove>> arrivals,
  required Bucket selected,
  required ValueChanged<Bucket> onSelect,
}) {
  return ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      _BucketStrip(
        composition: result,
        selected: selected,
        onSelect: onSelect,
      ),
      // Only show the editor when there's a non-zero portfolio to allocate.
      // Zero-portfolio members (or the goal-scoped empty state) keep the
      // simpler strip + detail-card layout.
      if (result.totalValue > 0)
        _BucketAllocatorSection(
          memberId: memberId,
          composition: result,
        ),
      BucketCompositionCard(
        bc: result.bucket(selected),
        arrivals: arrivals[selected] ?? const [],
      ),
    ],
  );
}

Widget _error(BuildContext context, Object e) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.loss, size: 40),
            const SizedBox(height: 8),
            Text('$e',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textSecondary)),
          ],
        ),
      ),
    );

// ─── Goal-scoped composition builder ───────────────────────────────────────

BucketCompositionResult _buildGoalComposition({
  required GoalModel goal,
  required List<GoalModel> goalsInScope,
  required List<GoalFundLink> links,
  required List<FundHoldingSummary> holdings,
  required dynamic ideal,
  required bool autoAttach,
}) {
  final sortedGoals = [...goalsInScope]
    ..sort((a, b) => a.targetDateTime.compareTo(b.targetDateTime));
  final defaultByTerm = <GoalTerm, String>{};
  for (final g in sortedGoals) {
    defaultByTerm.putIfAbsent(g.term, () => g.id);
  }
  final explicit = <int, String>{};
  for (final l in links) {
    if (goalsInScope.any((g) => g.id == l.goalId)) {
      explicit[l.amfiCode] = l.goalId;
    }
  }
  final linkedFunds = <FundHoldingSummary>[];
  for (final h in holdings) {
    final pinned = explicit[h.amfiCode];
    if (pinned != null) {
      if (pinned == goal.id) linkedFunds.add(h);
      continue;
    }
    if (!autoAttach) continue;
    final term = classifyFundTerm(h);
    if (defaultByTerm[term] == goal.id) linkedFunds.add(h);
  }

  final fundsByBucket = <Bucket, List<HoldingLine>>{
    for (final b in Bucket.values) b: <HoldingLine>[],
  };
  for (final f in linkedFunds) {
    final bucket = bucketFor(
      resolveAssetClass(
        amfiCategoryId: f.amfiCategoryId,
        assetClassLabel: f.assetClassLabel,
        category: f.category,
      ),
      TaxCategory.fromString(f.taxCategory),
    );
    fundsByBucket[bucket]!.add(HoldingLine(
      holding: f,
      effectiveBucket: bucket,
      isOverridden: false,
    ));
  }

  final currentByBucket = {
    for (final b in Bucket.values)
      b: fundsByBucket[b]!.fold<double>(0, (s, l) => s + l.holding.currentValue),
  };
  final total = currentByBucket.values.fold<double>(0, (s, v) => s + v);
  final targetPctByBucket = computeGoalBucketTarget(goal, ideal, DateTime.now());

  final buckets = <BucketComposition>[];
  for (final b in Bucket.values) {
    final current = currentByBucket[b]!;
    final currentPct = total == 0 ? 0.0 : (current / total) * 100;
    final targetPct = targetPctByBucket[b] ?? 0.0;
    buckets.add(BucketComposition(
      bucket: b,
      currentValue: current,
      currentPct: currentPct,
      targetPct: targetPct,
      gapPct: currentPct - targetPct,
      gapRupees: current - (goal.targetAmount * targetPct / 100.0),
      funds: List.unmodifiable(fundsByBucket[b]!),
      otherAssets: const [],
      goalAlerts: const [],
    ));
  }
  return BucketCompositionResult(
    buckets: List.unmodifiable(buckets),
    totalValue: total,
  );
}

// ─── Strip of 3 bucket silhouettes ────────────────────────────────────────

class _BucketStrip extends StatelessWidget {
  const _BucketStrip({
    required this.composition,
    required this.selected,
    required this.onSelect,
  });

  final BucketCompositionResult composition;
  final Bucket selected;
  final ValueChanged<Bucket> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in Bucket.values)
            Expanded(
              child: _BucketSilhouette(
                bc: composition.bucket(b),
                selected: b == selected,
                onTap: () => onSelect(b),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Single bucket silhouette card ────────────────────────────────────────

class _BucketSilhouette extends StatelessWidget {
  const _BucketSilhouette({
    required this.bc,
    required this.selected,
    required this.onTap,
  });

  final BucketComposition bc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = bc.bucket.color;
    // Colour-code the gap readout per AppColors semantic palette.
    final gapColor = bc.gapPct.abs() < 2
        ? AppColors.gain
        : (bc.gapPct > 0 ? AppColors.loss : AppColors.info);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : palette.bgDivider,
            width: selected ? 1.6 : 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The vertically-elongated bucket silhouette with fill + target
            // lining. Scale: current% / target% mapped to 0–100 of a
            // full-portfolio axis → easy to see over/under-weight at a glance.
            SizedBox(
              width: 56,
              height: 100,
              child: CustomPaint(
                painter: _BucketPainter(
                  color: color,
                  fillColor: color.withValues(alpha: 0.28),
                  currentPct: bc.currentPct,
                  targetPct: bc.targetPct,
                  rimColor: color,
                  dashColor: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bc.bucket.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cur ${bc.currentPct.toStringAsFixed(0)}% · '
              'Tgt ${bc.targetPct.toStringAsFixed(0)}%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: palette.textSecondary),
            ),
            Text(
              '${bc.gapPct >= 0 ? '+' : ''}${bc.gapPct.toStringAsFixed(1)}pp',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: gapColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for the vertically-elongated bucket shape. Renders an
/// inverted trapezoid (wide top, narrow bottom), fills from the bottom up
/// to `currentPct / 100` of the inner height, and draws a dashed horizontal
/// tick at `targetPct / 100` — the "target lining".
class _BucketPainter extends CustomPainter {
  _BucketPainter({
    required this.color,
    required this.fillColor,
    required this.currentPct,
    required this.targetPct,
    required this.rimColor,
    required this.dashColor,
  });

  final Color color;
  final Color fillColor;
  final double currentPct;
  final double targetPct;
  final Color rimColor;
  final Color dashColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry. Top rim sits a little below 0 to leave room for the ellipse.
    const rimY = 6.0;
    final bottomY = size.height - 4;
    const topInset = 4.0;
    final bottomInset = size.width * 0.18;
    const topL = Offset(topInset, rimY);
    final topR = Offset(size.width - topInset, rimY);
    final botR = Offset(size.width - bottomInset, bottomY);
    final botL = Offset(bottomInset, bottomY);

    final body = Path()
      ..moveTo(topL.dx, topL.dy)
      ..lineTo(topR.dx, topR.dy)
      ..lineTo(botR.dx, botR.dy)
      ..lineTo(botL.dx, botL.dy)
      ..close();

    // Fill — clipped to bucket body.
    final fillFrac = (currentPct / 100).clamp(0.0, 1.0);
    final fillTopY = bottomY - (bottomY - rimY) * fillFrac;
    canvas.save();
    canvas.clipPath(body);
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRect(
      Rect.fromLTRB(0, fillTopY, size.width, bottomY),
      fillPaint,
    );
    canvas.restore();

    // Body outline.
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(body, outline);

    // Rim ellipse on top — gives the bucket its "opening" look.
    final rimPaint = Paint()
      ..color = rimColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, rimY),
        width: size.width - topInset * 2,
        height: 6,
      ),
      rimPaint,
    );

    // Target "lining" — dashed horizontal tick inside the bucket at the
    // target fill level.
    final targetFrac = (targetPct / 100).clamp(0.0, 1.0);
    final targetY = bottomY - (bottomY - rimY) * targetFrac;
    // Interpolate the trapezoid's x bounds at targetY.
    final t = (bottomY - targetY) / (bottomY - rimY); // 0 at bottom, 1 at top
    final xLeft = bottomInset - (bottomInset - topInset) * t;
    final xRight = (size.width - bottomInset) +
        (bottomInset - topInset) * t;

    final dashPaint = Paint()
      ..color = dashColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 3.5;
    const dashGap = 2.5;
    double x = xLeft + 1;
    while (x < xRight - 1) {
      final x2 = (x + dashWidth).clamp(xLeft, xRight);
      canvas.drawLine(Offset(x, targetY), Offset(x2, targetY), dashPaint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _BucketPainter old) =>
      old.color != color ||
      old.fillColor != fillColor ||
      old.currentPct != currentPct ||
      old.targetPct != targetPct ||
      old.rimColor != rimColor ||
      old.dashColor != dashColor;
}

// ─── Bucket allocator (3 sliders + sum indicator + Saved chip) ──────────

/// Lets the user set a custom target % for each of the 3 buckets. Edits
/// persist via [simulationStateProvider]`.setBucketTarget`; the sum of the
/// three values is reported live at the bottom (green when ≈100%, red
/// otherwise). Defaults to the bucket composition's `targetPct` (derived
/// from risk profile) so first-render shows a sensible starting state.
class _BucketAllocatorSection extends ConsumerStatefulWidget {
  const _BucketAllocatorSection({
    required this.memberId,
    required this.composition,
  });

  final String? memberId;
  final BucketCompositionResult composition;

  @override
  ConsumerState<_BucketAllocatorSection> createState() =>
      _BucketAllocatorSectionState();
}

class _BucketAllocatorSectionState
    extends ConsumerState<_BucketAllocatorSection> {
  DateTime? _lastSavedAt;

  double _defaultTargetPct(Bucket b) =>
      widget.composition.bucket(b).targetPct;

  double _effectiveTargetPct(SimulationState sim, Bucket b) =>
      sim.bucketTargets[b.name] ?? _defaultTargetPct(b);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final memberId = widget.memberId;

    ref.listen<SimulationState>(simulationStateProvider(memberId),
        (prev, next) {
      if (prev == null || identical(prev, next)) return;
      if (!mounted) return;
      // Only bump the timestamp when the bucket targets actually changed —
      // the same provider also drives fund/class edits and we want a
      // per-surface Saved indicator.
      if (prev.bucketTargets != next.bucketTargets) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });

    final simState = ref.watch(simulationStateProvider(memberId));
    final total = widget.composition.totalValue;
    final sumPct = Bucket.values.fold<double>(
        0, (s, b) => s + _effectiveTargetPct(simState, b));
    final balanced = (sumPct - 100).abs() < 0.1;
    final indicatorColor = balanced ? AppColors.gain : AppColors.loss;
    final indicatorLabel = balanced
        ? 'Balanced 100%'
        : (sumPct > 100
            ? 'Over ${sumPct.toStringAsFixed(1)}%'
            : 'Short ${sumPct.toStringAsFixed(1)}%');

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: palette.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Bucket targets',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Portfolio ${total.toINRCompact()}',
                style: TextStyle(
                    fontSize: 10, color: palette.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final b in Bucket.values)
            _BucketSliderRow(
              key: ValueKey('bucket_slider_${b.name}'),
              bucket: b,
              targetPct: _effectiveTargetPct(simState, b),
              portfolioTotal: total,
              currentPct: widget.composition.bucket(b).currentPct,
              onChanged: (pct) => ref
                  .read(simulationStateProvider(memberId).notifier)
                  .setBucketTarget(b.name, pct),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: indicatorColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      balanced ? Icons.check_circle : Icons.error_outline,
                      size: 13,
                      color: indicatorColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      indicatorLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: indicatorColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_lastSavedAt != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_outlined,
                        size: 13, color: palette.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Saved \u00B7 ${_fmtTime(_lastSavedAt!)}',
                      style: TextStyle(
                          fontSize: 11, color: palette.textTertiary),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// One bucket row: name + color dot + multi-segment slider + paired ₹/%
/// inputs. Follows the same visual language as the class-level slider in
/// the Fund tab — green to current, red-for-deficit / amber-for-excess
/// overlay from current to target.
class _BucketSliderRow extends StatefulWidget {
  const _BucketSliderRow({
    super.key,
    required this.bucket,
    required this.targetPct,
    required this.portfolioTotal,
    required this.currentPct,
    required this.onChanged,
  });

  final Bucket bucket;
  final double targetPct;
  final double portfolioTotal;
  final double currentPct;
  final ValueChanged<double> onChanged;

  @override
  State<_BucketSliderRow> createState() => _BucketSliderRowState();
}

class _BucketSliderRowState extends State<_BucketSliderRow> {
  late final TextEditingController _rupeesCtrl;
  late final TextEditingController _pctCtrl;
  final FocusNode _rupeesFocus = FocusNode();
  final FocusNode _pctFocus = FocusNode();
  final _rupeesFmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _rupeesCtrl = TextEditingController(text: _rupeesFmt.format(_rupees.round()));
    _pctCtrl = TextEditingController(text: widget.targetPct.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(_BucketSliderRow old) {
    super.didUpdateWidget(old);
    if (old.targetPct != widget.targetPct && !_pctFocus.hasFocus) {
      _pctCtrl.text = widget.targetPct.toStringAsFixed(1);
    }
    if ((old.targetPct != widget.targetPct ||
            old.portfolioTotal != widget.portfolioTotal) &&
        !_rupeesFocus.hasFocus) {
      _rupeesCtrl.text = _rupeesFmt.format(_rupees.round());
    }
  }

  @override
  void dispose() {
    _rupeesCtrl.dispose();
    _pctCtrl.dispose();
    _rupeesFocus.dispose();
    _pctFocus.dispose();
    super.dispose();
  }

  double get _rupees => widget.portfolioTotal * widget.targetPct / 100.0;

  void _commitPct(double pct) {
    final clamped = pct.clamp(0.0, 100.0);
    if (!_pctFocus.hasFocus) {
      _pctCtrl.text = clamped.toStringAsFixed(1);
    }
    if (!_rupeesFocus.hasFocus) {
      _rupeesCtrl.text = _rupeesFmt
          .format((widget.portfolioTotal * clamped / 100.0).round());
    }
    widget.onChanged(clamped);
  }

  void _onRupeesText(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty || widget.portfolioTotal <= 0) {
      _commitPct(0);
      return;
    }
    final rupees = double.tryParse(digits) ?? 0;
    _commitPct((rupees / widget.portfolioTotal) * 100.0);
  }

  void _onPctText(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) {
      _commitPct(0);
      return;
    }
    final pct = double.tryParse(clean);
    if (pct == null) return;
    _commitPct(pct);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bucketColor = widget.bucket.color;
    final cur = widget.currentPct.clamp(0.0, 100.0);
    final tgt = widget.targetPct.clamp(0.0, 100.0);
    final deficit = tgt > cur + 0.1;
    final excess = tgt < cur - 0.1;
    final overlayColor = deficit
        ? AppColors.loss
        : excess
            ? AppColors.warning
            : AppColors.gain;
    final lo = cur < tgt ? cur : tgt;
    final hi = cur > tgt ? cur : tgt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: bucketColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.bucket.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Cur ${cur.toStringAsFixed(1)}%',
                style:
                    TextStyle(fontSize: 10, color: palette.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Multi-segment track.
          SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(builder: (context, c) {
                    final w = c.maxWidth;
                    return Stack(
                      children: [
                        Positioned.fill(
                          top: 12,
                          bottom: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.bgSurface,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 0,
                          height: 6,
                          width: w * (lo / 100),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.gain,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        if (deficit || excess)
                          Positioned(
                            top: 12,
                            left: w * (lo / 100),
                            height: 6,
                            width: w * ((hi - lo) / 100),
                            child: Container(
                              decoration: BoxDecoration(
                                color: overlayColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: overlayColor,
                    overlayColor:
                        overlayColor.withValues(alpha: 0.18),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: tgt,
                    min: 0,
                    max: 100,
                    divisions: 200,
                    onChanged: _commitPct,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _rupeesCtrl,
                  focusNode: _rupeesFocus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style:
                      TextStyle(fontSize: 12, color: palette.textPrimary),
                  decoration: InputDecoration(
                    prefixText: '₹',
                    labelText: 'Target value',
                    labelStyle: TextStyle(
                        fontSize: 10, color: palette.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onRupeesText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _pctCtrl,
                  focusNode: _pctFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style:
                      TextStyle(fontSize: 12, color: palette.textPrimary),
                  decoration: InputDecoration(
                    suffixText: '%',
                    labelText: 'Target %',
                    labelStyle: TextStyle(
                        fontSize: 10, color: palette.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    filled: true,
                    fillColor: palette.bgSurface,
                    border: const OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onPctText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Goal filter banner ────────────────────────────────────────────────────

class _GoalBanner extends ConsumerWidget {
  const _GoalBanner({required this.goal});
  final GoalModel goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.bgSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Filtered by goal: ${goal.goalName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(selectedGoalFilterProvider.notifier).clear(),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

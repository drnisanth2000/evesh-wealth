import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/asset_classes.dart';
import '../../../../core/constants/bucket_mapping.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/pending_order_model.dart';
import '../../../../domain/usecases/compute_deployment_plan.dart';
import '../../../../domain/usecases/resolve_rebalance_destination.dart';
import '../../../../domain/usecases/run_rebalance_analysis.dart';
import '../../../providers/bucket_composition_provider.dart';
import '../../../providers/pending_moves_provider.dart';
import '../../../providers/pending_orders_provider.dart';
import '../../../providers/rebalance_dismissal_provider.dart';
import '../../../providers/rebalance_provider.dart';
import '../../../providers/selected_member_provider.dart';
import '../../../providers/simulation_provider.dart';
import '../../../widgets/wealth_planner/move_card.dart';

/// Mirrors the lookup in `rebalance_provider._labelToAssetClass`. Kept local
/// so synthesized user-target-driven sells don't need to go through the
/// provider path.
AssetClass _labelToAssetClass(String label) {
  final l = label.toLowerCase();
  if (l.contains('core equity') || l.contains('equity')) {
    return AssetClass.coreEquity;
  }
  if (l.contains('satellite')) return AssetClass.satelliteEquity;
  if (l.contains('hybrid')) return AssetClass.hybrid;
  if (l.contains('debt')) return AssetClass.debt;
  if (l.contains('liquid')) return AssetClass.liquid;
  if (l.contains('gold')) return AssetClass.gold;
  return AssetClass.alternate;
}

/// Stable hash for a suggestion, used for dismissal + execution de-dup.
/// Formerly lived in `rebal_suggested_tab.dart`; moved here as part of the
/// v3 rebalance topology switch (Phase 7).
/// driftPct is deliberately NOT part of the key: it moves with daily NAV,
/// so including it made a dismissed suggestion resurface as "new" whenever
/// the drift crossed a rounding boundary (5.4% → 5.6% ⇒ different hash).
String suggestionHashOf({
  required String? memberId,
  required int amfiCode,
  required String action,
}) {
  final raw = '${memberId ?? 'all'}|$amfiCode|$action';
  return raw.hashCode.toUnsigned(32).toRadixString(16);
}

/// Merged Suggested + Deployment. Reallocation MoveCards for existing drift
/// suggestions, then a Lumpsum/SIP/Split form that produces Deployment
/// MoveCards. All MoveCards write into [pendingMovesProvider] so the Buckets
/// sub-tab paints "Arriving" rows.
class RebalActionsTab extends ConsumerStatefulWidget {
  const RebalActionsTab({super.key});

  @override
  ConsumerState<RebalActionsTab> createState() => _RebalActionsTabState();
}

class _RebalActionsTabState extends ConsumerState<RebalActionsTab> {
  final _lumpsumCtrl = TextEditingController();
  final _sipCtrl = TextEditingController();
  _DeployMode _mode = _DeployMode.split;
  double _splitPct = 30;
  DeploymentPlan? _plan;
  bool _computing = false;

  /// Per-amfi GlobalKey map — lets us `Scrollable.ensureVisible` the card
  /// matching `?focus=<amfiCode>` when the user deep-links here from a
  /// holding row or a Fund sub-card's 3-dot menu.
  final Map<int, GlobalKey> _cardKeys = {};
  int? _lastFocusedAmfi;
  int? _highlightAmfi;
  GlobalKey _keyFor(int amfi) =>
      _cardKeys.putIfAbsent(amfi, () => GlobalKey());

  void _maybeFocus(BuildContext context) {
    // GoRouterState.of throws when we're not inside a GoRouter subtree (e.g.
    // in widget tests that pump this tab directly). Focus is a nice-to-have;
    // swallow and skip.
    String? raw;
    try {
      raw = GoRouterState.of(context).uri.queryParameters['focus'];
    } catch (_) {
      return;
    }
    final amfi = raw == null ? null : int.tryParse(raw);
    if (amfi == null || amfi == _lastFocusedAmfi) return;
    _lastFocusedAmfi = amfi;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _cardKeys[amfi]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
      setState(() => _highlightAmfi = amfi);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() {
          if (_highlightAmfi == amfi) _highlightAmfi = null;
        });
      });
    });
  }

  double get _lumpsum {
    if (_mode == _DeployMode.sip) return 0;
    return double.tryParse(_lumpsumCtrl.text) ?? 0;
  }

  double get _sip {
    if (_mode == _DeployMode.lumpsum) return 0;
    return double.tryParse(_sipCtrl.text) ?? 0;
  }

  double get _effectiveSplit => switch (_mode) {
        _DeployMode.lumpsum => 100,
        _DeployMode.sip => 0,
        _DeployMode.split => _splitPct,
      };

  @override
  void dispose() {
    _lumpsumCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    final memberId = ref.read(selectedMemberProvider);
    setState(() => _computing = true);
    try {
      final comp =
          await ref.read(bucketCompositionProvider(memberId).future);
      final plan = computeDeploymentPlan(
        lumpsum: _lumpsum,
        sip: _sip,
        splitPct: _effectiveSplit,
        composition: comp,
      );
      if (!mounted) return;
      setState(() => _plan = plan);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Compute failed: $e')));
    } finally {
      if (mounted) setState(() => _computing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeFocus(context);
    final memberId = ref.watch(selectedMemberProvider);
    final analysisAsync = ref.watch(rebalanceAnalysisProvider(memberId));
    final compositionAsync = ref.watch(bucketCompositionProvider(memberId));
    final dismissalsAsync = ref.watch(rebalanceDismissalsProvider(memberId));

    return analysisAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (analysis) => compositionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (composition) => dismissalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (dismissals) {
            final dismissed =
                dismissals.map((d) => d.suggestionHash).toSet();

            // Per-fund target rupee amounts sourced from the Fund sub-tab
            // sliders (persisted in simulationStateProvider). When untouched,
            // initFromHoldings seeds these to current values → resolver falls
            // back to largest-current (legacy behaviour).
            final simState =
                ref.watch(simulationStateProvider(memberId));
            final perFundTargets = simState.fundAmounts;

            // Build a per-fund dictionary of all holdings for lookup.
            final amfiToHolding = {
              for (final bc in composition.buckets)
                for (final line in bc.funds)
                  line.holding.amfiCode: (
                    holding: line.holding,
                    bucket: bc.bucket,
                  ),
            };
            final amfiToCurrent = {
              for (final e in amfiToHolding.entries)
                e.key: e.value.holding.currentValue,
            };

            // ── User-target-driven sell suggestions ────────────────────
            // When user sets a fund's Fund-tab target below its current
            // value, generate an explicit sell. This fills the gap where
            // rebalanceAnalysisProvider only emits asset-class-drift
            // suggestions and wouldn't fire for per-fund intent.
            final userDrivenSells = <FundRebalanceSuggestion>[];
            perFundTargets.forEach((amfi, target) {
              final entry = amfiToHolding[amfi];
              if (entry == null) return;
              final delta = entry.holding.currentValue - target;
              if (delta <= 1.0) return;
              userDrivenSells.add(FundRebalanceSuggestion(
                amfiCode: amfi,
                fundName: entry.holding.fundName,
                assetClass: _labelToAssetClass(
                  entry.holding.assetClassLabel ??
                      entry.holding.category ??
                      '',
                ),
                driftPct: 0.0,
                currentValue: entry.holding.currentValue,
                suggestedAction: RebalanceAction.reduce,
                suggestedAmount: delta,
              ));
            });

            // ── Drift-driven sell suggestions from asset-class analysis ─
            final driftSells = analysis.topFundSuggestions.where((s) {
              if (s.suggestedAction != RebalanceAction.reduce) return false;
              return !dismissed.contains(suggestionHashOf(
                memberId: memberId,
                amfiCode: s.amfiCode,
                action: s.suggestedAction.name,
              ));
            }).toList();

            // Merge — user-driven wins on amfiCode collision. Then drop
            // dismissed entries.
            final byAmfi = <int, FundRebalanceSuggestion>{};
            for (final s in driftSells) {
              byAmfi[s.amfiCode] = s;
            }
            for (final s in userDrivenSells) {
              byAmfi[s.amfiCode] = s;
            }
            final reallocSuggestions = byAmfi.values.where((s) {
              return !dismissed.contains(suggestionHashOf(
                memberId: memberId,
                amfiCode: s.amfiCode,
                action: s.suggestedAction.name,
              ));
            }).toList()
              // Biggest sells first.
              ..sort((a, b) =>
                  b.suggestedAmount.compareTo(a.suggestedAmount));

            final customTargetCount = perFundTargets.entries.where((e) {
              final current = amfiToCurrent[e.key];
              if (current == null) return false;
              return (e.value - current).abs() > 1.0;
            }).length;

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _TargetsBanner(count: customTargetCount),
                const SizedBox(height: 8),
                _ReallocationSection(
                  suggestions: reallocSuggestions,
                  composition: composition,
                  perFundTargets: perFundTargets,
                  memberId: memberId,
                  cardKeyFor: _keyFor,
                  highlightAmfi: _highlightAmfi,
                ),
                const SizedBox(height: 16),
                _deploymentSection(composition, memberId),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _deploymentSection(
    BucketCompositionResult composition,
    String? memberId,
  ) {
    final plan = _plan;
    final lineCount = plan == null
        ? 0
        : plan.buckets.fold<int>(0, (s, b) => s + b.lines.length);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              color: Bucket.growth.color,
              title: 'Deploy fresh money',
              subtitle: 'Lumpsum, SIP, or split into deficient buckets',
              count: lineCount,
            ),
            const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _lumpsumCtrl,
                enabled: _mode != _DeployMode.sip,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lumpsum (₹)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _sipCtrl,
                enabled: _mode != _DeployMode.lumpsum,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SIP (₹/mo)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          SegmentedButton<_DeployMode>(
            segments: const [
              ButtonSegment(value: _DeployMode.lumpsum, label: Text('Lumpsum')),
              ButtonSegment(value: _DeployMode.sip, label: Text('SIP')),
              ButtonSegment(value: _DeployMode.split, label: Text('Split')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode == _DeployMode.split) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text('Lumpsum ${_splitPct.toStringAsFixed(0)}%'),
              Expanded(
                child: Slider(
                  value: _splitPct,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => setState(() => _splitPct = v),
                ),
              ),
              Text('SIP ${(100 - _splitPct).toStringAsFixed(0)}%'),
            ]),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _computing ? null : _compute,
              child: const Text('Compute'),
            ),
          ),
          if (_plan != null) ...[
            const SizedBox(height: 14),
            for (final bucket in _plan!.buckets)
              for (final line in bucket.lines)
                _DeploymentMoveCard(
                  line: line,
                  bucket: bucket.bucket,
                  composition: composition,
                  memberId: memberId,
                ),
          ],
          ],
        ),
      ),
    );
  }
}

enum _DeployMode { lumpsum, sip, split }

// ── Reallocation section ────────────────────────────────────────────────

class _ReallocationSection extends ConsumerWidget {
  const _ReallocationSection({
    required this.suggestions,
    required this.composition,
    required this.perFundTargets,
    required this.memberId,
    required this.cardKeyFor,
    required this.highlightAmfi,
  });

  final List<FundRebalanceSuggestion> suggestions;
  final BucketCompositionResult composition;
  final Map<int, double> perFundTargets;
  final String? memberId;

  /// Returns a stable GlobalKey for a suggestion card keyed by AMFI code so
  /// the parent tab can `Scrollable.ensureVisible` on deep-link.
  final GlobalKey Function(int amfi) cardKeyFor;

  /// The AMFI whose card should render a 2-second highlight ring.
  final int? highlightAmfi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              color: Bucket.liquid.color,
              title: 'Reallocate from existing funds',
              subtitle: 'Move money out of over-weight holdings',
              count: suggestions.length,
            ),
            const SizedBox(height: 12),
            if (suggestions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: palette.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                      'No reallocation needed — portfolio is within drift bounds',
                      style: TextStyle(
                          fontSize: 12, color: palette.textTertiary)),
                ]),
              )
            else
              ..._prepared(composition, suggestions, perFundTargets).map(
                (p) => Container(
                  key: cardKeyFor(p.suggestion.amfiCode),
                  decoration: p.suggestion.amfiCode == highlightAmfi
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.info,
                            width: 2,
                          ),
                          color: AppColors.info.withValues(alpha: 0.06),
                        )
                      : null,
                  padding: p.suggestion.amfiCode == highlightAmfi
                      ? const EdgeInsets.all(2)
                      : EdgeInsets.zero,
                  child: _ReallocationMoveCard(
                    suggestion: p.suggestion,
                    composition: composition,
                    destination: p.destination,
                    memberId: memberId,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pre-computes destinations for every reallocation suggestion in-order,
/// feeding each resolver call:
///   - [perFundTargets] — the user's Asset Allocation → Fund sliders (source
///     of truth for per-fund target rupee amounts).
///   - A growing `claimed` map — so back-to-back suggestions don't pile
///     every rupee into the same destination fund (concentration fix).
List<_PreparedMove> _prepared(
  BucketCompositionResult composition,
  List<FundRebalanceSuggestion> suggestions,
  Map<int, double> perFundTargets,
) {
  final claimed = <int, double>{};
  final out = <_PreparedMove>[];
  for (final s in suggestions) {
    final dest = resolveReduceDestination(
      composition: composition,
      fromAmfiCode: s.amfiCode,
      perFundTargets: perFundTargets,
      claimedByAmfi: claimed,
    );
    if (dest?.toAmfiCode != null) {
      claimed[dest!.toAmfiCode!] =
          (claimed[dest.toAmfiCode!] ?? 0) + s.suggestedAmount;
    }
    out.add(_PreparedMove(suggestion: s, destination: dest));
  }
  return out;
}

class _PreparedMove {
  const _PreparedMove({required this.suggestion, required this.destination});
  final FundRebalanceSuggestion suggestion;
  final RebalanceDestination? destination;
}

class _ReallocationMoveCard extends ConsumerWidget {
  const _ReallocationMoveCard({
    required this.suggestion,
    required this.composition,
    required this.destination,
    required this.memberId,
  });

  final FundRebalanceSuggestion suggestion;
  final BucketCompositionResult composition;
  final RebalanceDestination? destination;
  final String? memberId;

  String get _hash => suggestionHashOf(
        memberId: memberId,
        amfiCode: suggestion.amfiCode,
        action: suggestion.suggestedAction.name,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fromBucket = bucketFor(suggestion.assetClass);
    final toBucket = destination?.toBucket ?? Bucket.liquid;
    final destOptions = composition
        .bucket(toBucket)
        .funds
        .map((l) => l.holding)
        .toList();

    return MoveCard(
      id: _hash,
      kind: PendingMoveKind.reallocation,
      fromBucket: fromBucket,
      fromAmfi: suggestion.amfiCode,
      fromFundName: suggestion.fundName,
      toBucket: toBucket,
      initialToAmfi: destination?.toAmfiCode,
      initialToFundName: destination?.toFundName,
      initialAmount: suggestion.suggestedAmount,
      destinationOptions: destOptions,
      toBucketCurrentValue: composition.bucket(toBucket).currentValue,
      reason: destination?.reason,
      onSave: () => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved locally'))),
      onDismiss: () async {
        try {
          await ref.read(rebalanceDismissalsMutatorProvider.notifier).dismiss(
                suggestionHash: _hash,
                memberId: memberId,
                fromAmfiCode: suggestion.amfiCode,
                driftPct: suggestion.driftPct,
                reason: 'user dismiss',
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Dismissed — see Dismissed tab')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Dismiss failed: $e')));
          }
        }
      },
      onExecute: (toAmfi, toName, amount) async {
        try {
          final kind = toAmfi != null ? OrderKind.switchOrder : OrderKind.sell;
          await ref.read(pendingOrdersMutatorProvider.notifier).add(
                fundName: suggestion.fundName,
                kind: kind,
                amfiCode: suggestion.amfiCode,
                switchToAmfi: toAmfi,
                amount: amount,
                status: OrderStatus.placed,
                source: OrderSource.rebalance,
                memberId: memberId,
                notes: toAmfi != null
                    ? 'Switch: ${suggestion.fundName} → $toName'
                    : 'Sell to bank — redeploy later',
              );
          await ref
              .read(rebalanceDismissalsMutatorProvider.notifier)
              .dismiss(
                suggestionHash: _hash,
                memberId: memberId,
                fromAmfiCode: suggestion.amfiCode,
                driftPct: suggestion.driftPct,
                reason: 'executed',
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Order recorded — see Order Status tab')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Execute failed: $e')));
          }
        }
      },
    );
  }
}

// ── Deployment line → MoveCard ─────────────────────────────────────────

class _DeploymentMoveCard extends ConsumerWidget {
  const _DeploymentMoveCard({
    required this.line,
    required this.bucket,
    required this.composition,
    required this.memberId,
  });

  final DeploymentLine line;
  final Bucket bucket;
  final BucketCompositionResult composition;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = 'deploy|${bucket.name}|${line.amfiCode ?? "new"}|${line.assetClassLabel}';
    final amount = line.lumpsum + line.sip * 12;
    final destOptions =
        composition.bucket(bucket).funds.map((l) => l.holding).toList();

    return MoveCard(
      id: id,
      kind: PendingMoveKind.deployment,
      // "Fresh capital" has no source fund; we paint the From pill as Liquid
      // as a visual proxy for "cash arriving".
      fromBucket: Bucket.liquid,
      fromAmfi: null,
      fromFundName: line.lumpsum > 0 && line.sip > 0
          ? 'Fresh capital (LS ${line.lumpsum.toINRCompact()} + SIP ${line.sip.toINRCompact()}/mo)'
          : line.lumpsum > 0
              ? 'Fresh lumpsum'
              : 'Fresh SIP',
      toBucket: bucket,
      initialToAmfi: line.amfiCode,
      initialToFundName: line.fundName,
      initialAmount: amount,
      destinationOptions: destOptions,
      toBucketCurrentValue: composition.bucket(bucket).currentValue,
      reason:
          '${bucket.displayName} underweight — deploy ${amount.toINRCompact()} (${line.assetClassLabel})',
      onSave: () => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved locally'))),
      onDismiss: () {},
      onExecute: (toAmfi, toName, _) async {
        if (toAmfi == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pick a destination fund first')));
          return;
        }
        try {
          final mutator = ref.read(pendingOrdersMutatorProvider.notifier);
          if (line.lumpsum > 0) {
            await mutator.add(
              fundName: toName,
              kind: OrderKind.lumpsum,
              amfiCode: toAmfi,
              amount: line.lumpsum,
              status: OrderStatus.placed,
              source: OrderSource.deployment,
              memberId: memberId,
            );
          }
          if (line.sip > 0) {
            await mutator.add(
              fundName: toName,
              kind: OrderKind.sip,
              amfiCode: toAmfi,
              amount: line.sip,
              status: OrderStatus.placed,
              source: OrderSource.deployment,
              memberId: memberId,
            );
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Order recorded — see Order Status tab')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Execute failed: $e')));
          }
        }
      },
    );
  }
}


/// Top-of-tab banner showing whether any custom Fund-tab targets are in play.
/// Closes the "did my slider change propagate here?" loop with a visible
/// count, and nudges the user to Fund-tab when no targets are set.
class _TargetsBanner extends StatelessWidget {
  const _TargetsBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = count > 0;
    final color = active ? AppColors.primary : palette.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: active ? 0.30 : 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.tune,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active
                  ? 'Using $count custom Fund-tab target${count == 1 ? '' : 's'} to steer reallocation.'
                  : 'Tip: set per-fund targets in Asset Allocation → Fund to steer reallocation.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? palette.textPrimary : palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header shared by the Reallocation and Deployment cards — mirrors
/// the Goals page's TermCard header (left color bar + title + subtitle +
/// count badge) so the three surfaces feel consistent.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  final Color color;
  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 8,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: palette.textTertiary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

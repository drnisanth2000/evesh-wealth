import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';
import '../../../domain/usecases/compute_portfolio_overlap.dart';
import '../../providers/overlap_provider.dart';
import '../../providers/portfolio_provider.dart';
import 'traffic_light.dart';

/// Pre-buy portfolio fit section shown on the Fund Detail screen.
///
/// Evaluates how adding this fund would impact the user's portfolio:
/// - Skipped if the fund is already held
/// - Shows overlap risk, sector impact, and stock concentration shifts
/// - Includes a collapsible "What does this mean?" educational tooltip
class PortfolioFitSection extends ConsumerWidget {
  const PortfolioFitSection({
    super.key,
    required this.amfiCode,
    required this.fundName,
    this.memberId,
  });

  final int amfiCode;
  final String fundName;
  final String? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Step 1: check if already held ─────────────────────────────────────
    final summaryAsync = ref.watch(portfolioSummaryProvider(memberId));

    final isAlreadyHeld = summaryAsync.valueOrNull?.fundHoldings
            .any((h) => h.amfiCode == amfiCode) ??
        false;

    if (isAlreadyHeld) {
      return const SizedBox.shrink();
    }

    // ── Step 2: load portfolio holdings & candidate holdings ───────────────
    final currentHoldingsAsync =
        ref.watch(portfolioHoldingsProvider(memberId));
    final candidateAsync =
        ref.watch(candidateFundHoldingsProvider(amfiCode, fundName));

    // ── Loading state ──────────────────────────────────────────────────────
    final isLoading = currentHoldingsAsync.isLoading || candidateAsync.isLoading;
    if (isLoading) {
      return _SectionShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Analyzing portfolio fit...',
                style: TextStyle(
                  fontSize: 13,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Error state ────────────────────────────────────────────────────────
    if (currentHoldingsAsync.hasError || candidateAsync.hasError) {
      return _SectionShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Could not load fund holdings',
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      );
    }

    final currentFunds = currentHoldingsAsync.valueOrNull ?? [];
    final candidateFund = candidateAsync.valueOrNull;

    // Candidate fund data not available yet (null but no error)
    if (candidateFund == null) {
      return _SectionShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Fund holdings not yet available',
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      );
    }

    // ── Step 3: run computation ────────────────────────────────────────────
    final analysis = PortfolioOverlapCalculator.computePreBuy(
      currentFunds: currentFunds,
      candidateFund: candidateFund,
    );

    return _PortfolioFitBody(analysis: analysis, fundName: fundName);
  }
}

// ── Thin shell with section header ────────────────────────────────────────────

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Portfolio Fit',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ── Main body rendered when data is ready ─────────────────────────────────────

class _PortfolioFitBody extends StatefulWidget {
  const _PortfolioFitBody({
    required this.analysis,
    required this.fundName,
  });

  final PreBuyAnalysis analysis;
  final String fundName;

  @override
  State<_PortfolioFitBody> createState() => _PortfolioFitBodyState();
}

class _PortfolioFitBodyState extends State<_PortfolioFitBody> {
  bool _tooltipExpanded = false;

  String _overlapLabel(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 'low',
      RiskLevel.moderate => 'moderate',
      RiskLevel.high => 'high',
    };
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final candidateRisk = analysis.candidateRisk;
    final changedSectors =
        analysis.sectorDeltas.where((s) => s.changed).toList();
    final top5Stocks = analysis.stockDeltas.take(5).toList();
    final overlapLabel = _overlapLabel(candidateRisk);

    // Average overlap % across new overlapping fund pairs
    final avgOverlapPct = analysis.newOverlaps.isNotEmpty
        ? analysis.newOverlaps
                .map((o) => o.overlapPct)
                .reduce((a, b) => a + b) /
            analysis.newOverlaps.length
        : 0.0;

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Overall badge + summary ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.palette.bgDivider),
            ),
            child: Row(
              children: [
                TrafficLight(
                  risk: candidateRisk,
                  percentage: avgOverlapPct,
                  compact: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This fund has $overlapLabel overlap with your portfolio',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Overlap with held funds ──────────────────────────────────────
        if (analysis.newOverlaps.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Overlap with held funds:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.newOverlaps.map((pair) {
                final displayName =
                    _pairOtherFundName(pair, widget.fundName);

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.palette.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.palette.bgDivider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TrafficLight(
                        risk: pair.risk,
                        percentage: pair.overlapPct,
                        compact: true,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Sector impact ────────────────────────────────────────────────
        if (changedSectors.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Sector impact:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: changedSectors.map((sector) {
                return DeltaIndicator(
                  label: sector.sectorName,
                  beforePct: sector.beforePct,
                  afterPct: sector.afterPct,
                  beforeRisk: sector.beforeRisk,
                  afterRisk: sector.afterRisk,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Stock impact ─────────────────────────────────────────────────
        if (top5Stocks.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Stock impact:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: top5Stocks.map((stock) {
                return DeltaIndicator(
                  label: stock.companyName,
                  beforePct: stock.beforePct,
                  afterPct: stock.afterPct,
                  beforeRisk: stock.beforeRisk,
                  afterRisk: stock.afterRisk,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── "What does this mean?" educational tooltip ───────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EducationalTooltip(
            expanded: _tooltipExpanded,
            onToggle: () =>
                setState(() => _tooltipExpanded = !_tooltipExpanded),
          ),
        ),

        const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Return the fund name in the pair that is NOT the candidate fund.
  String _pairOtherFundName(FundPairOverlap pair, String candidateName) {
    if (pair.fundNameA == candidateName) return pair.fundNameB;
    if (pair.fundNameB == candidateName) return pair.fundNameA;
    // Fallback: use fundNameB (other held fund)
    return pair.fundNameB;
  }
}

// ── Collapsible educational tooltip ───────────────────────────────────────────

class _EducationalTooltip extends StatelessWidget {
  const _EducationalTooltip({
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tap area
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: context.palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: context.palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable body
          if (expanded) ...[
            Divider(
              height: 1,
              color: context.palette.bgDivider,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TooltipItem(
                    emoji: '🟢',
                    label: 'Low overlap',
                    body:
                        'Less than 35% of stocks are shared between this fund and your held funds. Adding it improves diversification.',
                  ),
                  SizedBox(height: 10),
                  _TooltipItem(
                    emoji: '🟡',
                    label: 'Moderate overlap',
                    body:
                        '35–50% of stocks overlap with your existing funds. This reduces diversification benefit but may still be acceptable.',
                  ),
                  SizedBox(height: 10),
                  _TooltipItem(
                    emoji: '🔴',
                    label: 'High overlap',
                    body:
                        'More than 50% of stocks are already in your portfolio. Per SEBI Feb 2026 guidelines, high overlap limits diversification and may increase concentration risk.',
                  ),
                  SizedBox(height: 10),
                  _TooltipItem(
                    emoji: '📊',
                    label: 'Sector & stock impact',
                    body:
                        'Arrows show how each sector or stock weight would change if you add this fund at a 10% portfolio allocation. A risk level change (🟡→🔴) signals a concentration warning.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TooltipItem extends StatelessWidget {
  const _TooltipItem({
    required this.emoji,
    required this.label,
    required this.body,
  });

  final String emoji;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: context.palette.textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

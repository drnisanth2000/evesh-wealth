// lib/presentation/screens/suggestions/suggestions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/suggestion_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/recommendations/recommendation_card.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  final _surplusCtrl = TextEditingController(text: '10000');

  @override
  void dispose() {
    _surplusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(surplusAmountNotifierProvider);
    final notifier = ref.read(surplusAmountNotifierProvider.notifier);
    final recAsync = ref.watch(fundRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Recommendations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Surplus input ──────────────────────────────────────────────
          Text(
            'Surplus Amount to Invest (₹)',
            style: TextStyle(fontSize: 12, color: context.palette.textTertiary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _surplusCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '₹ '),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(_surplusCtrl.text);
                  if (v != null && v > 0) {
                    notifier.set(v);
                    ref.invalidate(fundRecommendationsProvider);
                  }
                },
                child: const Text('Recommend'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Results ────────────────────────────────────────────────────
          recAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.loss, size: 40),
                    const SizedBox(height: 8),
                    Text('Error: $e',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.palette.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            data: (result) {
              if (result.recommendations.isEmpty) {
                return _EmptyState(
                  fundsEvaluated: result.fundsEvaluated,
                  fundsPassedGate: result.fundsPassedGate,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SIP / Lumpsum advice banner ──
                  _AdviceBanner(
                    sipRecommended: result.sipRecommended,
                    rationale: result.sipRationale,
                  ),
                  const SizedBox(height: 12),

                  // ── Pipeline stats ──
                  _PipelineStats(
                    fundsEvaluated: result.fundsEvaluated,
                    fundsPassedGate: result.fundsPassedGate,
                    recommendationCount: result.recommendations.length,
                  ),
                  const SizedBox(height: 12),

                  // ── Allocation gaps summary ──
                  if (result.allocationGaps.isNotEmpty) ...[
                    _GapSummary(gaps: result.allocationGaps),
                    const SizedBox(height: 16),
                  ],

                  // ── Recommendation cards ──
                  Text(
                    'Recommended Funds',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...result.recommendations.map((rec) => RecommendationCard(
                        recommendation: rec,
                        onTap: () => context.go(
                            '${Routes.fundMaster}/${rec.fundScore.amfiCode}'),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _AdviceBanner extends StatelessWidget {
  const _AdviceBanner({
    required this.sipRecommended,
    required this.rationale,
  });

  final bool sipRecommended;
  final String rationale;

  @override
  Widget build(BuildContext context) {
    final color = sipRecommended ? AppColors.primary : AppColors.gain;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            sipRecommended ? Icons.repeat : Icons.bolt,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rationale,
              style: TextStyle(
                  fontSize: 12, color: context.palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineStats extends StatelessWidget {
  const _PipelineStats({
    required this.fundsEvaluated,
    required this.fundsPassedGate,
    required this.recommendationCount,
  });

  final int fundsEvaluated;
  final int fundsPassedGate;
  final int recommendationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip('$fundsEvaluated evaluated'),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward, size: 12, color: context.palette.textTertiary),
        const SizedBox(width: 6),
        _StatChip('$fundsPassedGate passed gate'),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward, size: 12, color: context.palette.textTertiary),
        const SizedBox(width: 6),
        _StatChip('$recommendationCount picks', highlight: true),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, {this.highlight = false});
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.12)
            : context.palette.bgCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.3)
              : context.palette.bgDivider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: highlight ? AppColors.primary : context.palette.textTertiary,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _GapSummary extends StatelessWidget {
  const _GapSummary({required this.gaps});
  final Map<String, double> gaps;

  static const _labels = <String, String>{
    'coreEquity': 'Core Equity',
    'satelliteEquity': 'Satellite Equity',
    'hybrid': 'Hybrid',
    'debt': 'Debt',
    'liquid': 'Liquid',
    'gold': 'Gold',
    'alternatives': 'Alternate',
  };

  @override
  Widget build(BuildContext context) {
    final entries = gaps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entries.map((e) {
        final label = _labels[e.key] ?? e.key;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$label −${e.value.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.fundsEvaluated,
    required this.fundsPassedGate,
  });

  final int fundsEvaluated;
  final int fundsPassedGate;

  @override
  Widget build(BuildContext context) {
    final reason = fundsEvaluated == 0
        ? 'No fund data available.'
        : fundsPassedGate == 0
            ? 'No funds passed the quality gate ($fundsEvaluated evaluated).'
            : 'Your portfolio allocation is on target — no rebalancing needed.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.gain, size: 48),
            const SizedBox(height: 12),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.palette.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

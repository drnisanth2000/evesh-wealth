import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/asset_classes.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/usecases/run_fifo_tax_calculator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/reconciliation_provider.dart';
import '../../providers/tax_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/member_selector.dart';

class TaxScreen extends ConsumerStatefulWidget {
  const TaxScreen({super.key});

  @override
  ConsumerState<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends ConsumerState<TaxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String? _selectedMemberId; // null = "All"

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Summary'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
              label: const Text('Import Tax',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              onPressed: () => context.push(Routes.uploadTax),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Realized Gains'),
            Tab(text: 'Unrealized Exposure'),
            Tab(text: 'Harvest'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Disclaimer banner
          GestureDetector(
            onTap: () => context.push(Routes.uploadTax),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warning.withValues(alpha: 0.08),
                    AppColors.warning.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.warning.withValues(alpha: 0.2)),
                  left: BorderSide(
                      color: AppColors.warning, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estimates only \u2014 upload AIS PDF or CAMS statement for verified tax data.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.warning.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Upload',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Member selector chips (All / Eva / ...) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: MemberSelector(
              selectedMemberId: _selectedMemberId,
              onSelected: (id) => setState(() => _selectedMemberId = id),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RealizedGainsTab(selectedMemberId: _selectedMemberId),
                _UnrealizedExposureTab(selectedMemberId: _selectedMemberId),
                _HarvestTab(selectedMemberId: _selectedMemberId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1: Realized Gains
// ══════════════════════════════════════════════════════════════════════════════
class _RealizedGainsTab extends ConsumerWidget {
  const _RealizedGainsTab({this.selectedMemberId});
  final String? selectedMemberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxAsync = ref.watch(taxCalculationProvider);
    final camsAsync = ref.watch(camsTaxStatementProvider);
    final aisAsync = ref.watch(aisStatementProvider);

    return taxAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (result) {
        final camsData = camsAsync.valueOrNull?.forMember(selectedMemberId);
        final aisData = aisAsync.valueOrNull?.forMember(selectedMemberId);

        // Filter by selected member
        final summaries = selectedMemberId == null
            ? result.memberSummaries
            : result.memberSummaries
                .where((m) => m.memberId == selectedMemberId)
                .toList();

        final hasAisData = aisData != null && aisData.hasData;
        final hasVerifiedData = camsData != null && camsData.hasData;

        // Show AIS even when no FIFO summaries (user may have wiped transactions)
        if (summaries.isEmpty && !hasAisData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: context.palette.textTertiary),
                const SizedBox(height: 12),
                Text('No redemptions in this FY',
                    style: TextStyle(color: context.palette.textSecondary, fontSize: 15)),
                const SizedBox(height: 4),
                Text(result.financialYear.fyDisplay,
                    style: TextStyle(
                        color: context.palette.textTertiary, fontSize: 13)),
              ],
            ),
          );
        }

        // Build a filtered result for summary cards
        final filteredTotalLtcg = summaries.fold(0.0, (s, m) => s + m.equityLtcgGain);
        final filteredTotalStcg = summaries.fold(0.0, (s, m) => s + m.equityStcgGain);
        final filteredTotalGoldLtcg = summaries.fold(0.0, (s, m) => s + m.goldLtcgGain);
        final filteredTotalGoldStcg = summaries.fold(0.0, (s, m) => s + m.goldStcgGain);
        final filteredTotalDebt = summaries.fold(0.0, (s, m) => s + m.debtSlabGain);
        final filteredTotalLoss = summaries.fold(0.0, (s, m) => s + m.totalLoss);
        final filteredTotalTax = summaries.fold(0.0, (s, m) => s + m.totalTax);
        final filteredTotalGrandfathering = summaries.fold(0.0, (s, m) => s + m.grandfatheringBenefit);

        final isSingleMember = summaries.length == 1;
        final slabRate = summaries.isNotEmpty
            ? summaries.first.taxSlabPct
            : 0.30;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Page-level slab rate selector ──
            if (isSingleMember)
              _SlabRateBar(member: summaries.first),

            // ── AIS verified data (highest priority — IT Department source) ──
            if (hasAisData) ...[
              _AisVerifiedCard(ais: aisData!, slabRate: slabRate),
              const SizedBox(height: 12),
            ],

            // ── When CAMS verified data exists, show it as PRIMARY ──
            if (hasVerifiedData && !hasAisData) ...[
              _CamsVerifiedPrimaryCard(
                cams: camsData!,
                slabRate: slabRate,
              ),
              const SizedBox(height: 12),
            ],

            // ── When CAMS data exists alongside AIS, show it as secondary ──
            if (hasVerifiedData && hasAisData) ...[
              _CamsVerifiedPrimaryCard(
                cams: camsData!,
                slabRate: slabRate,
              ),
              const SizedBox(height: 12),
            ],

            // Per-member eVesh FIFO details
            if (summaries.isNotEmpty) ...[
              ...summaries.map((m) => _MemberTaxCard(
                member: m,
                showMemberName: !isSingleMember,
                isPrimary: !hasVerifiedData && !hasAisData,
              )),
            ],

            // ── CAMS vs FIFO comparison ──
            if (hasVerifiedData && summaries.isNotEmpty)
              _CamsVsFifoComparison(
                cams: camsData!,
                fifoSummaries: summaries,
                slabRate: slabRate,
              ),

            // ── No verified data → show eVesh estimate as primary ──
            if (!hasVerifiedData && !hasAisData && summaries.isNotEmpty) ...[
              _FilteredSummaryCard(
                fy: result.financialYear,
                totalGain: filteredTotalLtcg + filteredTotalStcg +
                    filteredTotalGoldLtcg + filteredTotalGoldStcg +
                    filteredTotalDebt - filteredTotalLoss,
                totalTax: filteredTotalTax,
                grandfatheringBenefit: filteredTotalGrandfathering,
              ),
              const SizedBox(height: 16),

              _FilteredBreakdownRow(
                equityLtcg: filteredTotalLtcg,
                equityStcg: filteredTotalStcg,
                goldLtcg: filteredTotalGoldLtcg,
                goldStcg: filteredTotalGoldStcg,
                debt: filteredTotalDebt,
              ),
              const SizedBox(height: 20),
            ],
          ],
        );
      },
    );
  }
}

class _FilteredSummaryCard extends StatelessWidget {
  const _FilteredSummaryCard({
    required this.fy,
    required this.totalGain,
    required this.totalTax,
    required this.grandfatheringBenefit,
  });
  final String fy;
  final double totalGain;
  final double totalTax;
  final double grandfatheringBenefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.palette.bgCard, context.palette.bgCardElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fy.fyDisplay,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(
                'Est. Tax: ${totalTax.toINRCompact()}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.palette.loss),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Total Realized Gains',
              style: TextStyle(color: context.palette.textTertiary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(totalGain.toINRCompact(),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary)),
          if (grandfatheringBenefit > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 13, color: context.palette.gain),
                const SizedBox(width: 4),
                Text(
                  'Grandfathering saved ${grandfatheringBenefit.toINRCompact()}',
                  style: TextStyle(fontSize: 11, color: context.palette.gain),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilteredBreakdownRow extends StatelessWidget {
  const _FilteredBreakdownRow({
    required this.equityLtcg,
    required this.equityStcg,
    required this.goldLtcg,
    required this.goldStcg,
    required this.debt,
  });
  final double equityLtcg;
  final double equityStcg;
  final double goldLtcg;
  final double goldStcg;
  final double debt;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, double amount, String rate, Color color})>[];

    if (equityLtcg > 0) {
      items.add((label: 'Eq LTCG', amount: equityLtcg,
          rate: '12.5%', color: AppColors.chartColors[0]));
    }
    if (equityStcg > 0) {
      items.add((label: 'Eq STCG', amount: equityStcg,
          rate: '20%', color: AppColors.chartColors[1]));
    }
    if (goldLtcg > 0) {
      items.add((label: 'Gold LTCG', amount: goldLtcg,
          rate: '12.5%', color: AppColors.chartColors[5]));
    }
    if (goldStcg > 0) {
      items.add((label: 'Gold STCG', amount: goldStcg,
          rate: 'Slab', color: AppColors.chartColors[6]));
    }
    if (debt > 0) {
      items.add((label: 'Debt', amount: debt,
          rate: 'Slab', color: AppColors.chartColors[4]));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items
          .map((item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label,
                          style: TextStyle(fontSize: 9, color: item.color)),
                      Text(item.amount.toINRCompact(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: item.color)),
                      Text('@ ${item.rate}',
                          style: TextStyle(
                              fontSize: 8,
                              color: item.color.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Page-level slab rate selector ────────────────────────────────────────────
class _SlabRateBar extends ConsumerWidget {
  const _SlabRateBar({required this.member});
  final MemberTaxSummary member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (member.taxSlabPct * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Row(
        children: [
          const Icon(Icons.percent, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Income Tax Slab Rate',
              style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSlabRateSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$pct%',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 12, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSlabRateSheet(BuildContext context, WidgetRef ref) {
    final slabRates = [0, 5, 10, 15, 20, 25, 30];
    final currentSlab = (member.taxSlabPct * 100).round();

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tax Slab Rate \u2014 ${member.memberName}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Applies to debt fund gains and CAMS non-equity STCG',
                style: TextStyle(
                    fontSize: 12, color: context.palette.textSecondary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slabRates
                  .map((rate) => ChoiceChip(
                        label: Text('$rate%'),
                        selected: currentSlab == rate,
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        onSelected: (_) async {
                          await ref
                              .read(supabaseClientProvider)
                              .from('family_members')
                              .update({'tax_slab_pct': rate.toDouble()})
                              .eq('id', member.memberId);
                          ref.invalidate(familyMembersProvider);
                          ref.invalidate(taxCalculationProvider);
                          ref.invalidate(taxHarvestOpportunitiesProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'New regime: 0% (<\u20b93L) \u2022 5% (\u20b93-7L) \u2022 10% (\u20b97-10L) \u2022 '
                '15% (\u20b910-12L) \u2022 20% (\u20b912-15L) \u2022 30% (>\u20b915L)\n'
                'Old regime: 0% (<\u20b92.5L) \u2022 5% (\u20b92.5-5L) \u2022 20% (\u20b95-10L) \u2022 '
                '30% (>\u20b910L)',
                style: TextStyle(
                    fontSize: 10,
                    color: context.palette.textSecondary,
                    height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Member Tax Card (eVesh FIFO estimate) ────────────────────────────────────
class _MemberTaxCard extends ConsumerStatefulWidget {
  const _MemberTaxCard({
    required this.member,
    this.showMemberName = true,
    this.isPrimary = true,
  });
  final MemberTaxSummary member;
  final bool showMemberName;
  final bool isPrimary;

  @override
  ConsumerState<_MemberTaxCard> createState() => _MemberTaxCardState();
}

class _MemberTaxCardState extends ConsumerState<_MemberTaxCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // When secondary (CAMS exists), start collapsed
    _expanded = widget.isPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final totalGain = member.equityLtcgGain + member.equityStcgGain +
        member.goldLtcgGain + member.goldStcgGain + member.debtSlabGain;
    final isGain = totalGain >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.palette.bgCard, context.palette.bgCardElevated],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.bgDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header bar ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: widget.isPrimary ? AppColors.primary : context.palette.textTertiary,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              child: Row(
                children: [
                  Icon(
                    widget.isPrimary ? Icons.auto_fix_high : Icons.analytics_outlined,
                    size: 16,
                    color: widget.isPrimary ? AppColors.primary : context.palette.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.isPrimary ? 'eVesh FIFO Estimate' : 'eVesh FIFO Details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.isPrimary ? AppColors.primary : context.palette.textTertiary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            if (widget.showMemberName) ...[
                              const SizedBox(width: 6),
                              Text('\u2022 ${member.memberName}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.palette.textTertiary)),
                            ],
                          ],
                        ),
                        if (!widget.isPrimary)
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Per-fund breakdown & loss offsets',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.palette.textTertiary,
                              ),
                            ),
                          ),
                        if (widget.isPrimary) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isGain ? context.palette.gain : context.palette.loss)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${totalGain.toINRCompact()} ${isGain ? 'gain' : 'loss'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isGain ? context.palette.gain : context.palette.loss,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.isPrimary)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Est. Tax',
                            style: TextStyle(
                                fontSize: 9,
                                color: context.palette.textTertiary,
                                letterSpacing: 0.3)),
                        Text(member.totalTax.toINRCompact(),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: context.palette.loss)),
                      ],
                    ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: widget.isPrimary ? AppColors.primary : context.palette.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // ── Detail rows (collapsible when secondary) ──
          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                // ── Tax calculation rows (only when primary) ──
                if (widget.isPrimary) ...[
                // Equity section
                if (member.equityLtcgGain > 0 ||
                    member.equityStcgGain > 0) ...[
                  _SectionLabel('Equity'),
                  if (member.equityLtcgGain > 0) ...[
                    _TaxRow('LTCG gains',
                        member.equityLtcgGain.toINRCompact()),
                    _TaxRow(
                        'Exemption used (\u20b91.25L)',
                        (-member.equityLtcgExemptionUsed)
                            .toINRCompact()),
                    _TaxRow('Taxable LTCG',
                        member.equityLtcgTaxableGain.toINRCompact(),
                        color: member.equityLtcgTaxableGain > 0
                            ? context.palette.loss
                            : context.palette.textSecondary),
                    _TaxRow('LTCG Tax (12.5%)',
                        member.equityLtcgTax.toINRCompact(),
                        color: context.palette.loss),
                  ],
                  if (member.equityStcgGain > 0) ...[
                    _TaxRow('STCG gains',
                        member.equityStcgGain.toINRCompact()),
                    _TaxRow('STCG Tax (20%)',
                        member.equityStcgTax.toINRCompact(),
                        color: context.palette.loss),
                  ],
                ],
                // Gold/FoF section
                if (member.goldLtcgGain > 0 ||
                    member.goldStcgGain > 0) ...[
                  const Divider(height: 20),
                  _SectionLabel('Gold / FoF'),
                  if (member.goldLtcgGain > 0) ...[
                    _TaxRow('LTCG gains (>24m)',
                        member.goldLtcgGain.toINRCompact()),
                    _TaxRow('LTCG Tax (12.5%)',
                        member.goldLtcgTax.toINRCompact(),
                        color: context.palette.loss),
                  ],
                  if (member.goldStcgGain > 0) ...[
                    _TaxRow('STCG gains (\u226424m)',
                        member.goldStcgGain.toINRCompact()),
                    _TaxRow('STCG Tax (slab)',
                        member.goldStcgTax.toINRCompact(),
                        color: context.palette.loss),
                  ],
                ],
                // Debt section
                if (member.debtSlabGain > 0) ...[
                  const Divider(height: 20),
                  _SectionLabel('Debt'),
                  _TaxRow('Gain (slab rate)',
                      member.debtSlabGain.toINRCompact()),
                  _TaxRow(
                      'Tax (${(member.taxSlabPct * 100).toStringAsFixed(0)}%)',
                      member.debtSlabTax.toINRCompact(),
                      color: context.palette.loss),
                ],

                // ── Total Tax footer ──
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.palette.loss.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: context.palette.loss.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_outlined,
                          size: 14, color: context.palette.loss),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Cess (4%) + Total Tax',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.palette.textSecondary)),
                      ),
                      Text(
                        '${member.cess.toINRCompact()} + ${(member.totalTax - member.cess).toINRCompact()} = ',
                        style: TextStyle(
                            fontSize: 10,
                            color: context.palette.textTertiary),
                      ),
                      Text(member.totalTax.toINRCompact(),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.palette.loss)),
                    ],
                  ),
                ),
                ], // end isPrimary tax rows

                // Grandfathering benefit
                if (member.grandfatheringBenefit > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.palette.gain.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: context.palette.gain.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: context.palette.gain),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Grandfathering saved ${member.grandfatheringBenefit.toINRCompact()}',
                              style: TextStyle(
                                  fontSize: 11, color: context.palette.gain),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loss offset info
                if (member.totalLoss > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.balance,
                                size: 14, color: AppColors.info),
                            const SizedBox(width: 6),
                            const Text('Capital Loss Offset',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _TaxRow('Total realized losses',
                            '-${member.totalLoss.toINRCompact()}',
                            color: context.palette.loss),
                        if (member.stLossOffsetVsStcg > 0)
                          _TaxRow('ST loss \u2192 STCG offset',
                              member.stLossOffsetVsStcg.toINRCompact(),
                              color: context.palette.gain),
                        if (member.stLossOffsetVsLtcg > 0)
                          _TaxRow('ST loss \u2192 LTCG offset',
                              member.stLossOffsetVsLtcg.toINRCompact(),
                              color: context.palette.gain),
                        if (member.ltLossOffsetVsLtcg > 0)
                          _TaxRow('LT loss \u2192 LTCG offset',
                              member.ltLossOffsetVsLtcg.toINRCompact(),
                              color: context.palette.gain),
                        if (member.lossCarryForward > 0)
                          _TaxRow('Carry forward (8 yrs)',
                              member.lossCarryForward.toINRCompact(),
                              color: AppColors.warning),
                      ],
                    ),
                  ),
                ],

                // Unused LTCG exemption
                if (member.unusedLtcgExemption > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.palette.gain.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: context.palette.gain.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.savings_outlined,
                              size: 14, color: context.palette.gain),
                          const SizedBox(width: 6),
                          Text(
                            '${member.unusedLtcgExemption.toINRCompact()} LTCG exemption remaining',
                            style: TextStyle(
                                fontSize: 11, color: context.palette.gain),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Per-fund breakdown — full table
                if (member.fundBreakdowns.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 20),
                  _SectionLabel('Per-Fund Breakdown'),
                  const SizedBox(height: 4),
                  _AdaptiveTable(
                    child: _FundBreakdownTable(funds: member.fundBreakdowns),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

/// Wraps a table widget in LayoutBuilder: fills width if enough space,
/// otherwise allows horizontal scroll.
class _AdaptiveTable extends StatelessWidget {
  const _AdaptiveTable({required this.child, this.minWidth = 550});
  final Widget child;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      if (available >= minWidth) {
        // Enough space — stretch to fill
        return SizedBox(width: available, child: child);
      }
      // Too narrow — scroll horizontally
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: minWidth, child: child),
      );
    });
  }
}

class _FundBreakdownTable extends StatelessWidget {
  const _FundBreakdownTable({required this.funds});
  final List<FundTaxBreakdown> funds;

  @override
  Widget build(BuildContext context) {
    final hStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.palette.textTertiary,
        letterSpacing: 0.3);

    // Totals
    double tCost = 0, tProceeds = 0, tStcg = 0, tLtcg = 0, tNet = 0;
    for (final f in funds) {
      tCost += f.totalCostBasis;
      tProceeds += f.totalSaleProceeds;
      tStcg += f.netStcg;
      tLtcg += f.netLtcg;
      tNet += f.netTotal;
    }

    Widget cell(double v,
        {bool isBold = false, bool isNeutral = false, bool isDebt = false}) {
      final color = isNeutral
          ? context.palette.textSecondary
          : isDebt
              ? AppColors.warning
              : (v >= 0 ? context.palette.gain : context.palette.loss);
      return Expanded(
        flex: 2,
        child: Text(
          v.abs() < 0.5 ? '\u2014' : v.toINRCompact(),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: v.abs() < 0.5 ? context.palette.textTertiary : color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    Widget nameCell(String name, TaxCategory cat) {
      final isEq = cat.isEquityType;
      final isGold = cat.isGoldFofType;
      final tag = isEq ? 'Eq' : isGold ? 'Gold' : 'Debt';
      final tagColor = isEq
          ? AppColors.primary
          : isGold
              ? AppColors.chartColors[5]
              : AppColors.warning;

      return Expanded(
        flex: 5,
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(tag,
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: tagColor)),
            ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: context.palette.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final visibleFunds = funds
        .where(
            (f) => f.netTotal.abs() > 0.5 || f.totalCostBasis.abs() > 0.5)
        .toList()
      ..sort((a, b) => a.fundName.compareTo(b.fundName));

    return Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Text('Scheme', style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Invested',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Redeemed',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('STCG',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('LTCG',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Net G/L',
                      textAlign: TextAlign.right, style: hStyle)),
            ]),
          ),
          // Data rows with alternating tint
          ...visibleFunds.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.transparent
                    : context.palette.bgSurface.withValues(alpha: 0.3),
              ),
              child: Row(children: [
                nameCell(f.fundName, f.taxCategory),
                cell(f.totalCostBasis, isNeutral: true),
                cell(f.totalSaleProceeds, isNeutral: true),
                cell(f.netStcg, isDebt: f.taxCategory.isDebtType),
                cell(f.netLtcg, isDebt: f.taxCategory.isDebtType),
                cell(f.netTotal, isDebt: f.taxCategory.isDebtType),
              ]),
            );
          }),
          // Totals row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              color: AppColors.primary.withValues(alpha: 0.04),
            ),
            child: Row(children: [
              Expanded(
                flex: 5,
                child: Text('Total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textPrimary)),
              ),
              cell(tCost, isBold: true, isNeutral: true),
              cell(tProceeds, isBold: true, isNeutral: true),
              cell(tStcg, isBold: true),
              cell(tLtcg, isBold: true),
              cell(tNet, isBold: true),
            ]),
          ),
        ],
    );
  }
}

class _TaxRow extends StatelessWidget {
  const _TaxRow(this.label, this.value, {this.color, this.bold = false});
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.palette.bgDivider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: bold
                        ? context.palette.textPrimary
                        : context.palette.textSecondary,
                    fontWeight:
                        bold ? FontWeight.w600 : FontWeight.normal,
                    letterSpacing: 0.1)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? context.palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AIS Verified Card — IT Department source of truth
// ══════════════════════════════════════════════════════════════════════════════
class _AisVerifiedCard extends StatefulWidget {
  const _AisVerifiedCard({required this.ais, required this.slabRate});
  final AisStatement ais;
  final double slabRate;

  @override
  State<_AisVerifiedCard> createState() => _AisVerifiedCardState();
}

class _AisVerifiedCardState extends State<_AisVerifiedCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final ais = widget.ais;
    final tax = ais.computeTax(slabRate: widget.slabRate);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.palette.gain.withValues(alpha: 0.05),
            context.palette.bgCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.palette.gain.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: context.palette.gain, width: 3),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              child: Row(
                children: [
                  Icon(Icons.verified, size: 18, color: context.palette.gain),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('AIS \u2014 Income Tax Dept',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.palette.gain,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: context.palette.gain.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(ais.financialYear.fyDisplay,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.gain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (ais.totalGain >= 0 ? context.palette.gain : context.palette.loss)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Total Gain: ${ais.totalGain.toINRCompact()}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ais.totalGain >= 0 ? context.palette.gain : context.palette.loss,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Est. Tax',
                          style: TextStyle(
                              fontSize: 9,
                              color: context.palette.textTertiary,
                              letterSpacing: 0.3)),
                      Text(tax.totalTax.toINRCompact(),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.palette.loss)),
                    ],
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: context.palette.gain,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──
          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              children: [
                // ── Capital Gains Breakdown ──
                // Stocks
                if (ais.stockStcg != 0 || ais.stockLtcg != 0) ...[
                  _SectionLabel('Stocks (${ais.stockSaleCount} sales)'),
                  if (ais.stockLtcg != 0)
                    _TaxRow('LTCG', ais.stockLtcg.toINRCompact(),
                        color: ais.stockLtcg >= 0 ? context.palette.gain : context.palette.loss),
                  if (ais.stockStcg != 0)
                    _TaxRow('STCG', ais.stockStcg.toINRCompact(),
                        color: ais.stockStcg >= 0 ? context.palette.gain : context.palette.loss),
                ],

                // Equity MF
                if (ais.eqMfStcg != 0 || ais.eqMfLtcg != 0) ...[
                  if (ais.stockStcg != 0 || ais.stockLtcg != 0)
                    const Divider(height: 16),
                  _SectionLabel('Equity MF (${ais.equityMfSales.length} lots)'),
                  if (ais.eqMfLtcg != 0)
                    _TaxRow('LTCG', ais.eqMfLtcg.toINRCompact(),
                        color: ais.eqMfLtcg >= 0 ? context.palette.gain : context.palette.loss),
                  if (ais.eqMfStcg != 0)
                    _TaxRow('STCG', ais.eqMfStcg.toINRCompact(),
                        color: ais.eqMfStcg >= 0 ? context.palette.gain : context.palette.loss),
                ],

                // Debt MF
                if (ais.debtMfStcg != 0 || ais.debtMfLtcg != 0) ...[
                  const Divider(height: 16),
                  _SectionLabel('Debt MF (${ais.debtMfSales.length} lots)'),
                  if (ais.debtMfLtcg != 0)
                    _TaxRow('LTCG', ais.debtMfLtcg.toINRCompact()),
                  if (ais.debtMfStcg != 0)
                    _TaxRow('STCG', ais.debtMfStcg.toINRCompact()),
                ],

                // ── Tax calculation ──
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.palette.loss.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.palette.loss.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      if (ais.totalEquityLtcg > 0) ...[
                        _TaxRow('Equity LTCG', ais.totalEquityLtcg.toINRCompact()),
                        _TaxRow('Exemption (\u20b91.25L)',
                            (-tax.ltcgExemptionUsed).toINRCompact()),
                        _TaxRow('LTCG Tax (12.5%)', tax.equityLtcgTax.toINRCompact(),
                            color: context.palette.loss),
                      ],
                      if (ais.totalEquityStcg > 0)
                        _TaxRow('STCG Tax (20%)', tax.equityStcgTax.toINRCompact(),
                            color: context.palette.loss),
                      if (ais.debtMfStcg > 0 || ais.debtMfLtcg > 0)
                        _TaxRow('Debt Tax (slab)', (tax.debtStcgTax + tax.debtLtcgTax).toINRCompact(),
                            color: context.palette.loss),
                      const Divider(height: 12),
                      _TaxRow('Cess (4%)', tax.cess.toINRCompact(), color: context.palette.loss),
                      _TaxRow('Total Tax', tax.totalTax.toINRCompact(),
                          color: context.palette.loss, bold: true),
                    ],
                  ),
                ),

                // ── TDS / Income summary ──
                if (ais.totalSalary > 0 || ais.totalDividends > 0 || ais.totalInterest > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Income & TDS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (ais.totalSalary > 0)
                          _TaxRow('Salary', ais.totalSalary.toINRCompact()),
                        if (ais.totalDividends > 0)
                          _TaxRow('Dividends', ais.totalDividends.toINRCompact()),
                        if (ais.totalInterest > 0)
                          _TaxRow('Interest', ais.totalInterest.toINRCompact()),
                        if (ais.totalTds > 0)
                          _TaxRow('TDS Deducted', ais.totalTds.toINRCompact(),
                              color: context.palette.gain),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CAMS Verified — shown as PRIMARY when available
// ══════════════════════════════════════════════════════════════════════════════
class _CamsVerifiedPrimaryCard extends StatefulWidget {
  const _CamsVerifiedPrimaryCard({
    required this.cams,
    this.slabRate = 0.30,
  });
  final CamsTaxStatement cams;
  final double slabRate;

  @override
  State<_CamsVerifiedPrimaryCard> createState() =>
      _CamsVerifiedPrimaryCardState();
}

class _CamsVerifiedPrimaryCardState extends State<_CamsVerifiedPrimaryCard> {
  bool _expanded = true;

  CamsTaxStatement get cams => widget.cams;
  double get slabRate => widget.slabRate;

  static Widget _camsChip(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: color)),
            Text('\u20b9${amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip (tap to collapse) ──
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CAMS / MF Central Verified',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.2)),
                        if (cams.investorName != null)
                          Text(
                              '${cams.investorName}${cams.pan != null ? ' \u2022 ${cams.pan}' : ''}',
                              style: TextStyle(
                                  fontSize: 10, color: context.palette.textTertiary)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(cams.financialYear.fyDisplay,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total verified gain — big number (per-lot for accuracy)
                Text('Total Verified Capital Gain',
                    style: TextStyle(
                        color: context.palette.textTertiary,
                        fontSize: 11,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Builder(builder: (_) {
                  final g = cams.perLotGains;
                  final total = cams.perLotTotalGain;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\u20b9${total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: total >= 0 ? context.palette.gain : context.palette.loss,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Breakdown chips
                      Row(
                        children: [
                          _camsChip('Eq STCG', g.eqStcg,
                              AppColors.chartColors[1]),
                          const SizedBox(width: 6),
                          _camsChip('Eq LTCG', g.eqLtcg,
                              AppColors.chartColors[0]),
                          const SizedBox(width: 6),
                          _camsChip('Non-Eq', g.neStcg + g.neLtcg,
                              AppColors.chartColors[4]),
                        ],
                      ),
                    ],
                  );
                }),
                if (cams.totalStt > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'STT Paid: \u20b9${cams.totalStt.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 10, color: context.palette.textTertiary),
                  ),
                ],

                // ── Tax Computation (same format as member card) ──
                const SizedBox(height: 12),
                const Divider(height: 20),
                Builder(builder: (context) {
                  final tax = cams.computeTax(slabRate: slabRate);
                  final cg = cams.perLotGains;
                  return Column(
                    children: [
                      // Equity section
                      if (cg.eqLtcg > 0 || cg.eqStcg > 0) ...[
                        const _SectionLabel('Equity'),
                        if (cg.eqLtcg > 0) ...[
                          _TaxRow('LTCG gains',
                              cg.eqLtcg.toINRCompact()),
                          _TaxRow(
                              'Exemption used (\u20b91.25L)',
                              (-tax.ltcgExemptionUsed).toINRCompact()),
                          _TaxRow(
                              'Taxable LTCG',
                              (cg.eqLtcg - tax.ltcgExemptionUsed)
                                  .toINRCompact(),
                              color: (cg.eqLtcg - tax.ltcgExemptionUsed) > 0
                                  ? context.palette.loss
                                  : context.palette.textSecondary),
                          _TaxRow('LTCG Tax (12.5%)',
                              tax.equityLtcgTax.toINRCompact(),
                              color: context.palette.loss),
                        ],
                        if (cg.eqStcg > 0) ...[
                          _TaxRow('STCG gains',
                              cg.eqStcg.toINRCompact()),
                          _TaxRow('STCG Tax (20%)',
                              tax.equityStcgTax.toINRCompact(),
                              color: context.palette.loss),
                        ],
                      ],
                      // Debt / Gold section
                      if (cg.neStcg > 0 ||
                          cg.neLtcg > 0) ...[
                        const Divider(height: 20),
                        const _SectionLabel('Debt / Gold'),
                        if (cg.neStcg > 0) ...[
                          _TaxRow('STCG gains (slab)',
                              cg.neStcg.toINRCompact()),
                          _TaxRow(
                              'STCG Tax (${(slabRate * 100).toStringAsFixed(0)}%)',
                              tax.nonEquityStcgTax.toINRCompact(),
                              color: context.palette.loss),
                        ],
                        if (cg.neLtcg > 0) ...[
                          _TaxRow('LTCG gains',
                              cg.neLtcg.toINRCompact()),
                          _TaxRow('LTCG Tax (12.5%)',
                              tax.nonEquityLtcgTax.toINRCompact(),
                              color: context.palette.loss),
                        ],
                      ],
                      // Cess & Total footer
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.palette.loss.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: context.palette.loss.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.receipt_outlined,
                                size: 14, color: context.palette.loss),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Cess (4%) + Total Tax',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: context.palette.textSecondary)),
                            ),
                            Text(
                              '${tax.cess.toINRCompact()} + ${(tax.totalTax - tax.cess).toINRCompact()} = ',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.palette.textTertiary),
                            ),
                            Text(tax.totalTax.toINRCompact(),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: context.palette.loss)),
                          ],
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.palette.gain.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: context.palette.gain.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: context.palette.gain),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Use this data for ITR filing \u2014 matches registrar records.',
                          style: TextStyle(fontSize: 11, color: context.palette.gain),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Per-Fund Breakdown from registrar ──
                if (cams.schemeBreakdowns.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.list_alt,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text('Per-Fund Breakdown (Registrar)',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AdaptiveTable(
                    child:
                        _CamsSchemeTable(schemes: cams.schemeBreakdowns),
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CAMS Scheme Breakdown Table (registrar per-fund data) ───────────────────
class _CamsSchemeTable extends StatelessWidget {
  const _CamsSchemeTable({required this.schemes});
  final List<Map<String, dynamic>> schemes;

  @override
  Widget build(BuildContext context) {
    final hStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.palette.textTertiary,
        letterSpacing: 0.3);
    // Compute totals
    double tCost = 0, tRedeemed = 0, tStcg = 0, tLtcg = 0;
    for (final s in schemes) {
      tCost += (s['cost'] as num?)?.toDouble() ?? 0;
      tRedeemed += (s['amount'] as num?)?.toDouble() ?? 0;
      tStcg += (s['short_term'] as num?)?.toDouble() ?? 0;
      tLtcg += ((s['lt_with_idx'] as num?)?.toDouble() ?? 0) +
          ((s['lt_no_idx'] as num?)?.toDouble() ?? 0);
    }
    final tNet = tStcg + tLtcg;

    Widget cell(double v,
        {bool isBold = false, bool isNeutral = false, bool isDebt = false}) {
      final color = isNeutral
          ? context.palette.textSecondary
          : isDebt
              ? AppColors.warning
              : (v >= 0 ? context.palette.gain : context.palette.loss);
      return Expanded(
        flex: 2,
        child: Text(
          v.abs() < 0.5 ? '\u2014' : v.toINRCompact(),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: v.abs() < 0.5 ? context.palette.textTertiary : color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    // Pre-filter visible schemes and sort alphabetically
    final visibleSchemes = <Map<String, dynamic>>[];
    for (final s in schemes) {
      final cost = (s['cost'] as num?)?.toDouble() ?? 0;
      final stcg = (s['short_term'] as num?)?.toDouble() ?? 0;
      final ltcg = ((s['lt_with_idx'] as num?)?.toDouble() ?? 0) +
          ((s['lt_no_idx'] as num?)?.toDouble() ?? 0);
      if ((stcg + ltcg).abs() >= 0.5 || cost.abs() >= 0.5) {
        visibleSchemes.add(s);
      }
    }
    visibleSchemes.sort((a, b) =>
        ((a['scheme'] as String?) ?? '').compareTo((b['scheme'] as String?) ?? ''));

    return Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Text('Scheme', style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Invested',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Redeemed',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('STCG',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('LTCG',
                      textAlign: TextAlign.right, style: hStyle)),
              Expanded(
                  flex: 2,
                  child: Text('Net G/L',
                      textAlign: TextAlign.right, style: hStyle)),
            ]),
          ),
          // Data rows with alternating tint
          ...visibleSchemes.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            var name = (s['scheme'] as String?) ?? 'Unknown';
            name = name
                .replaceAll(
                    RegExp(r'[(/]?[A-Z]{2}[A-Z0-9]{10}[)/]?'), '')
                .replaceAll(RegExp(r'^\s*[/\-]\s*'), '')
                .trim();
            final isEquity = s['is_equity'] as bool?;
            final isDebt = isEquity == false;
            final cost = (s['cost'] as num?)?.toDouble() ?? 0;
            final redeemed = (s['amount'] as num?)?.toDouble() ?? 0;
            final stcg = (s['short_term'] as num?)?.toDouble() ?? 0;
            final ltcg =
                ((s['lt_with_idx'] as num?)?.toDouble() ?? 0) +
                    ((s['lt_no_idx'] as num?)?.toDouble() ?? 0);
            final total = stcg + ltcg;

            final tag = isEquity == true ? 'Eq' : isDebt ? 'Debt' : '';
            final tagColor =
                isEquity == true ? AppColors.primary : AppColors.warning;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.transparent
                    : context.palette.bgSurface.withValues(alpha: 0.3),
              ),
              child: Row(children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      if (tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          margin: const EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: tagColor)),
                        ),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                cell(cost, isNeutral: true),
                cell(redeemed, isNeutral: true),
                cell(stcg, isDebt: isDebt),
                cell(ltcg, isDebt: isDebt),
                cell(total, isDebt: isDebt),
              ]),
            );
          }),
          // Totals row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              color: AppColors.primary.withValues(alpha: 0.04),
            ),
            child: Row(children: [
              Expanded(
                flex: 5,
                child: Text('Total',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textPrimary)),
              ),
              cell(tCost, isBold: true, isNeutral: true),
              cell(tRedeemed, isBold: true, isNeutral: true),
              cell(tStcg, isBold: true),
              cell(tLtcg, isBold: true),
              cell(tNet, isBold: true),
            ]),
          ),
        ],
    );
  }
}

// ── CAMS vs eVesh FIFO Comparison ────────────────────────────────────────────
class _CamsVsFifoComparison extends StatefulWidget {
  const _CamsVsFifoComparison({
    required this.cams,
    required this.fifoSummaries,
    required this.slabRate,
  });
  final CamsTaxStatement cams;
  final List<MemberTaxSummary> fifoSummaries;
  final double slabRate;

  @override
  State<_CamsVsFifoComparison> createState() => _CamsVsFifoComparisonState();
}

class _CamsVsFifoComparisonState extends State<_CamsVsFifoComparison> {
  bool _expanded = false;

  CamsTaxStatement get cams => widget.cams;
  List<MemberTaxSummary> get fifoSummaries => widget.fifoSummaries;
  double get slabRate => widget.slabRate;

  static Widget _fundDetailRow(BuildContext context, String label, double camsVal,
      double fifoVal, double diff, {bool isBold = false}) {
    final diffColor = diff.abs() < 0.5
        ? context.palette.textTertiary
        : diff > 0
            ? context.palette.gain
            : context.palette.loss;
    final fw = isBold ? FontWeight.w700 : FontWeight.w400;
    const fs = 10.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: TextStyle(
                    fontSize: fs,
                    fontWeight: fw,
                    color: isBold
                        ? context.palette.textPrimary
                        : context.palette.textTertiary)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              camsVal.abs() < 0.5 ? '\u2014' : camsVal.toINRCompact(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fs,
                fontWeight: fw,
                color: context.palette.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fifoVal.abs() < 0.5 ? '\u2014' : fifoVal.toINRCompact(),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fs,
                fontWeight: fw,
                color: context.palette.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              diff.abs() < 0.5
                  ? '\u2014'
                  : '${diff > 0 ? '+' : ''}${diff.toINRCompact()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fs,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: diffColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Try to match a CAMS scheme name to a FIFO fund name.
  /// Returns a similarity score (0-1). Higher = better match.
  static double _nameSimilarity(String camsName, String fifoName) {
    // Normalize both names
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[(/]?[a-z]{2}[a-z0-9]{10}[)/]?'), '')
        .replaceAll(RegExp(r'\b(direct|growth|plan|regular|fund|scheme|mutual)\b'), '')
        .replaceAll(RegExp(r'[-/\s]+'), ' ')
        .trim();
    final a = norm(camsName);
    final b = norm(fifoName);
    if (a.isEmpty || b.isEmpty) return 0;

    // Simple word overlap score
    final aWords = a.split(' ').where((w) => w.length > 2).toSet();
    final bWords = b.split(' ').where((w) => w.length > 2).toSet();
    if (aWords.isEmpty || bWords.isEmpty) return 0;
    final overlap = aWords.intersection(bWords).length;
    return overlap / aWords.union(bWords).length;
  }

  @override
  Widget build(BuildContext context) {
    // Aggregate eVesh FIFO totals across members (NET = gains minus losses)
    double fifoEqStcg = 0, fifoEqLtcg = 0;
    double fifoNeStcg = 0, fifoNeLtcg = 0;
    double fifoTotal = 0, fifoTax = 0;
    for (final m in fifoSummaries) {
      final netEqStcg = m.equityStcgGain - m.equityStcgLoss;
      final netEqLtcg = m.equityLtcgGain - m.equityLtcgLoss;
      final netNeStcg = (m.goldStcgGain - m.goldStcgLoss) +
          (m.debtSlabGain - m.debtSlabLoss);
      final netNeLtcg = m.goldLtcgGain - m.goldLtcgLoss;
      fifoEqStcg += netEqStcg;
      fifoEqLtcg += netEqLtcg;
      fifoNeStcg += netNeStcg;
      fifoNeLtcg += netNeLtcg;
      fifoTotal += netEqStcg + netEqLtcg + netNeStcg + netNeLtcg;
      fifoTax += m.totalTax;
    }

    // CAMS totals — use per-lot data (accurate) over XLSX summary
    final camsGains = cams.perLotGains;
    final camsTax = cams.computeTax(slabRate: slabRate);
    final camsTotal = camsGains.eqStcg + camsGains.eqLtcg +
        camsGains.neStcg + camsGains.neLtcg;

    final summaryRows = <_CompRow>[
      _CompRow('Eq STCG', camsGains.eqStcg, fifoEqStcg),
      _CompRow('Eq LTCG', camsGains.eqLtcg, fifoEqLtcg),
      _CompRow('Non-Eq STCG', camsGains.neStcg, fifoNeStcg),
      _CompRow('Non-Eq LTCG', camsGains.neLtcg, fifoNeLtcg),
      _CompRow('Total Gain', camsTotal, fifoTotal, isBold: true),
      _CompRow('Est. Tax', camsTax.totalTax, fifoTax,
          isBold: true, isTax: true),
    ];

    // ── Build fund-wise comparison ──
    // Collect all FIFO fund breakdowns
    final fifoFunds = <FundTaxBreakdown>[];
    for (final m in fifoSummaries) {
      fifoFunds.addAll(m.fundBreakdowns);
    }

    // Build per-ISIN gains from per-lot data (accurate vs SCHEMEWISE)
    final perLotByIsin = <String, ({double stcg, double ltcg})>{};
    for (final txn in cams.transactionDetails) {
      final isin = txn['isin']?.toString() ?? '';
      if (isin.isEmpty) continue;
      final existing = perLotByIsin[isin];
      final st = (txn['st_gain'] as num?)?.toDouble() ?? 0;
      final lt = ((txn['lt_no_idx'] as num?)?.toDouble() ?? 0) +
          ((txn['lt_with_idx'] as num?)?.toDouble() ?? 0);
      perLotByIsin[isin] = (
        stcg: (existing?.stcg ?? 0) + st,
        ltcg: (existing?.ltcg ?? 0) + lt,
      );
    }

    // Match CAMS schemes to FIFO funds by name similarity
    final fundRows = <_FundCompRow>[];
    final matchedFifoIndices = <int>{};

    for (final cs in cams.schemeBreakdowns) {
      final camsName = (cs['scheme'] as String?) ?? '';
      // Use per-lot gains when available (SCHEMEWISE can have column errors)
      final isinMatch = RegExp(r'INF[A-Z0-9]{9}').firstMatch(camsName);
      final perLot = isinMatch != null ? perLotByIsin[isinMatch.group(0)!] : null;
      final camsStcg = perLot?.stcg ?? (cs['short_term'] as num?)?.toDouble() ?? 0;
      final camsLtcg = perLot?.ltcg ?? (((cs['lt_with_idx'] as num?)?.toDouble() ?? 0) +
          ((cs['lt_no_idx'] as num?)?.toDouble() ?? 0));
      final camsGain = camsStcg + camsLtcg;
      if (camsGain.abs() < 0.5 &&
          ((cs['cost'] as num?)?.toDouble() ?? 0).abs() < 0.5) continue;

      // Find best matching FIFO fund
      int bestIdx = -1;
      double bestScore = 0.3; // minimum threshold
      for (int i = 0; i < fifoFunds.length; i++) {
        if (matchedFifoIndices.contains(i)) continue;
        final score = _nameSimilarity(camsName, fifoFunds[i].fundName);
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }

      final fifoGain = bestIdx >= 0 ? fifoFunds[bestIdx].netTotal : 0.0;
      final fifoStcg = bestIdx >= 0 ? fifoFunds[bestIdx].netStcg : 0.0;
      final fifoLtcg = bestIdx >= 0 ? fifoFunds[bestIdx].netLtcg : 0.0;
      final fifoCost = bestIdx >= 0 ? fifoFunds[bestIdx].totalCostBasis : 0.0;
      final fifoProceeds = bestIdx >= 0 ? fifoFunds[bestIdx].totalSaleProceeds : 0.0;
      final camsCost = (cs['cost'] as num?)?.toDouble() ?? 0;
      final camsProceeds = (cs['amount'] as num?)?.toDouble() ?? 0;

      // Clean CAMS name for display
      var displayName = camsName
          .replaceAll(RegExp(r'[(/]?[A-Z]{2}[A-Z0-9]{10}[)/]?'), '')
          .replaceAll(RegExp(r'^\s*[/\-]\s*'), '')
          .trim();
      if (displayName.length > 35) {
        displayName = '${displayName.substring(0, 32)}...';
      }

      fundRows.add(_FundCompRow(
        name: displayName,
        camsStcg: camsStcg,
        camsLtcg: camsLtcg,
        camsTotal: camsGain,
        camsCost: camsCost,
        camsProceeds: camsProceeds,
        fifoStcg: fifoStcg,
        fifoLtcg: fifoLtcg,
        fifoTotal: fifoGain,
        fifoCost: fifoCost,
        fifoProceeds: fifoProceeds,
        matched: bestIdx >= 0,
        fifoBuyLots: bestIdx >= 0 ? fifoFunds[bestIdx].buyLotCount : 0,
        fifoSellCount: bestIdx >= 0 ? fifoFunds[bestIdx].sellCount : 0,
        fifoBuyUnits: bestIdx >= 0 ? fifoFunds[bestIdx].totalBuyUnits : 0,
        fifoUnmatchedUnits: bestIdx >= 0 ? fifoFunds[bestIdx].unmatchedSellUnits : 0,
        camsSellCount: (cs['count'] as num?)?.toInt() ?? 0,
      ));

      if (bestIdx >= 0) matchedFifoIndices.add(bestIdx);
    }

    // Add unmatched FIFO funds
    for (int i = 0; i < fifoFunds.length; i++) {
      if (matchedFifoIndices.contains(i)) continue;
      final f = fifoFunds[i];
      if (f.netTotal.abs() < 0.5 && f.totalCostBasis.abs() < 0.5) continue;
      var displayName = f.fundName;
      if (displayName.length > 35) {
        displayName = '${displayName.substring(0, 32)}...';
      }
      fundRows.add(_FundCompRow(
        name: displayName,
        camsStcg: 0,
        camsLtcg: 0,
        camsTotal: 0,
        camsCost: 0,
        camsProceeds: 0,
        fifoStcg: f.netStcg,
        fifoLtcg: f.netLtcg,
        fifoTotal: f.netTotal,
        fifoCost: f.totalCostBasis,
        fifoProceeds: f.totalSaleProceeds,
        matched: false,
        fifoBuyLots: f.buyLotCount,
        fifoSellCount: f.sellCount,
        fifoBuyUnits: f.totalBuyUnits,
        fifoUnmatchedUnits: f.unmatchedSellUnits,
      ));
    }

    // Sort alphabetically by fund name
    fundRows.sort((a, b) => a.name.compareTo(b.name));

    final hStyle = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: context.palette.textTertiary,
        letterSpacing: 0.3);

    Widget compCell(double v, {bool isBold = false, bool isTax = false,
        bool isDiff = false}) {
      final diff = isDiff;
      Color color;
      if (isDiff) {
        color = v.abs() < 0.5
            ? context.palette.textTertiary
            : v > 0
                ? context.palette.gain
                : context.palette.loss;
      } else {
        color = isTax ? context.palette.loss : context.palette.textSecondary;
      }
      return Expanded(
        flex: 2,
        child: Text(
          v.abs() < 0.5
              ? '\u2014'
              : isDiff
                  ? '${v > 0 ? '+' : ''}${v.toINRCompact()}'
                  : v.toINRCompact(),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.bgDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header (tap to collapse)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.info.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('CAMS vs eVesh FIFO Comparison',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.info)),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
          ),

          // ── Summary comparison ──
          if (_expanded) Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox()),
                    Expanded(
                        flex: 2,
                        child: Text('CAMS',
                            textAlign: TextAlign.right, style: hStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('eVesh',
                            textAlign: TextAlign.right, style: hStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('Diff',
                            textAlign: TextAlign.right, style: hStyle)),
                  ],
                ),
                const Divider(height: 10),
                ...summaryRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final r = entry.value;
                  final diff = r.fifo - r.camsVal;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.transparent
                          : context.palette.bgSurface.withValues(alpha: 0.2),
                      border: r.isBold
                          ? Border(
                              top: BorderSide(
                                  color: context.palette.bgDivider
                                      .withValues(alpha: 0.6),
                                  width: 0.5))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(r.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: r.isBold
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: r.isBold
                                      ? context.palette.textPrimary
                                      : context.palette.textSecondary)),
                        ),
                        compCell(r.camsVal,
                            isBold: r.isBold, isTax: r.isTax),
                        compCell(r.fifo,
                            isBold: r.isBold, isTax: r.isTax),
                        compCell(diff,
                            isBold: r.isBold, isDiff: true),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Per-fund breakdown ──
          if (_expanded && fundRows.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.palette.bgSurface.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(color: context.palette.bgDivider),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_list_bulleted,
                      size: 12, color: context.palette.textTertiary),
                  const SizedBox(width: 6),
                  Text('Per-Fund Breakdown',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.palette.textTertiary,
                          letterSpacing: 0.3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Column(
                children: fundRows.map((f) {
                  final diff = f.fifoTotal - f.camsTotal;
                  final diffColor = diff.abs() < 0.5
                      ? context.palette.textTertiary
                      : diff > 0
                          ? context.palette.gain
                          : context.palette.loss;
                  final costDiff = f.fifoCost - f.camsCost;
                  final procDiff = f.fifoProceeds - f.camsProceeds;
                  final stcgDiff = f.fifoStcg - f.camsStcg;
                  final ltcgDiff = f.fifoLtcg - f.camsLtcg;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.palette.bgSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: context.palette.bgDivider.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fund name + total diff
                        Row(
                          children: [
                            if (!f.matched)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(f.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: context.palette.textPrimary)),
                            ),
                            Text(
                              diff.abs() < 0.5
                                  ? 'Match'
                                  : '${diff > 0 ? '+' : ''}${diff.toINRCompact()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: diff.abs() < 0.5
                                    ? context.palette.gain
                                    : diffColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Detail table
                        _AdaptiveTable(
                          minWidth: 400,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                      flex: 3, child: SizedBox()),
                                  Expanded(
                                      flex: 2,
                                      child: Text('CAMS',
                                          textAlign: TextAlign.right,
                                          style: hStyle)),
                                  Expanded(
                                      flex: 2,
                                      child: Text('eVesh',
                                          textAlign: TextAlign.right,
                                          style: hStyle)),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Diff',
                                          textAlign: TextAlign.right,
                                          style: hStyle)),
                                ],
                              ),
                              _fundDetailRow(context, 'Cost', f.camsCost,
                                  f.fifoCost, costDiff),
                              _fundDetailRow(context, 'Proceeds', f.camsProceeds,
                                  f.fifoProceeds, procDiff),
                              _fundDetailRow(context, 'STCG', f.camsStcg,
                                  f.fifoStcg, stcgDiff),
                              _fundDetailRow(context, 'LTCG', f.camsLtcg,
                                  f.fifoLtcg, ltcgDiff),
                              _fundDetailRow(context, 'Total', f.camsTotal,
                                  f.fifoTotal, diff,
                                  isBold: true),
                              // Diagnostic row
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.bug_report_outlined,
                                        size: 10, color: context.palette.textTertiary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'eVesh: ${f.fifoBuyLots} buy lots \u2022 ${f.fifoSellCount} sells'
                                      '${f.camsSellCount > 0 ? ' | CAMS: ${f.camsSellCount} sells' : ''}'
                                      '${f.fifoUnmatchedUnits > 0.01 ? ' | \u26a0 ${f.fifoUnmatchedUnits.toStringAsFixed(2)} unmatched units' : ''}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: context.palette.textTertiary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompRow {
  const _CompRow(this.label, this.camsVal, this.fifo,
      {this.isBold = false, this.isTax = false});
  final String label;
  final double camsVal;
  final double fifo;
  final bool isBold;
  final bool isTax;
}

class _FundCompRow {
  const _FundCompRow({
    required this.name,
    required this.camsStcg,
    required this.camsLtcg,
    required this.camsTotal,
    required this.camsCost,
    required this.camsProceeds,
    required this.fifoStcg,
    required this.fifoLtcg,
    required this.fifoTotal,
    required this.fifoCost,
    required this.fifoProceeds,
    required this.matched,
    this.fifoBuyLots = 0,
    this.fifoSellCount = 0,
    this.fifoBuyUnits = 0,
    this.fifoUnmatchedUnits = 0,
    this.camsSellCount = 0,
  });
  final String name;
  final double camsStcg, camsLtcg, camsTotal, camsCost, camsProceeds;
  final double fifoStcg, fifoLtcg, fifoTotal, fifoCost, fifoProceeds;
  final bool matched;
  final int fifoBuyLots;
  final int fifoSellCount;
  final double fifoBuyUnits;
  final double fifoUnmatchedUnits;
  final int camsSellCount;
}

// ══════════════════════════════════════════════════════════════════════════════
// ─── Unrealized Exposure sort options ─────────────────────────────────────────
enum _ExposureSort {
  gainDesc('Gain: High \u2192 Low'),
  gainAsc('Gain: Low \u2192 High'),
  taxDesc('Est. Tax: High \u2192 Low'),
  ltcgSoonAsc('LTCG Transition: Soonest'),
  holdingDesc('Holding: Longest First'),
  valueDesc('Value: High \u2192 Low'),
  nameAsc('Fund: A \u2192 Z');

  const _ExposureSort(this.label);
  final String label;
}

// Tab 2: Unrealized Exposure
// ══════════════════════════════════════════════════════════════════════════════
class _UnrealizedExposureTab extends ConsumerStatefulWidget {
  const _UnrealizedExposureTab({this.selectedMemberId});
  final String? selectedMemberId;

  @override
  ConsumerState<_UnrealizedExposureTab> createState() =>
      _UnrealizedExposureTabState();
}

class _UnrealizedExposureTabState
    extends ConsumerState<_UnrealizedExposureTab> {
  _ExposureSort _sort = _ExposureSort.gainDesc;

  void _applySortExposures(List<UnrealizedExposure> list) {
    switch (_sort) {
      case _ExposureSort.gainDesc:
        list.sort((a, b) => b.unrealisedGain.compareTo(a.unrealisedGain));
      case _ExposureSort.gainAsc:
        list.sort((a, b) => a.unrealisedGain.compareTo(b.unrealisedGain));
      case _ExposureSort.taxDesc:
        list.sort((a, b) => b.estimatedTax.compareTo(a.estimatedTax));
      case _ExposureSort.ltcgSoonAsc:
        // Already-LTCG (0 remaining) goes to bottom; soonest first
        list.sort((a, b) {
          final aVal = a.ltcgDaysRemaining == 0 ? 99999 : a.ltcgDaysRemaining;
          final bVal = b.ltcgDaysRemaining == 0 ? 99999 : b.ltcgDaysRemaining;
          return aVal.compareTo(bVal);
        });
      case _ExposureSort.holdingDesc:
        list.sort((a, b) => b.holdingDays.compareTo(a.holdingDays));
      case _ExposureSort.valueDesc:
        list.sort((a, b) => b.currentValue.compareTo(a.currentValue));
      case _ExposureSort.nameAsc:
        list.sort(
            (a, b) => a.fundName.toLowerCase().compareTo(b.fundName.toLowerCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exposureAsync = ref.watch(unrealizedExposureProvider);

    return exposureAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (result) {
        // Filter by selected member
        final exposures = widget.selectedMemberId == null
            ? [...result.exposures]
            : result.exposures
                .where((e) => e.memberId == widget.selectedMemberId)
                .toList();

        if (exposures.isEmpty) {
          return Center(
            child: Text('No active holdings found',
                style: TextStyle(color: context.palette.textSecondary)),
          );
        }

        // Apply sort
        _applySortExposures(exposures);

        final totalGain = exposures.fold(0.0, (s, e) => s + e.unrealisedGain);
        final totalTax = exposures.fold(0.0, (s, e) => s + e.estimatedTax);
        final soonCount = exposures
            .where((e) => e.ltcgDaysRemaining > 0 && e.ltcgDaysRemaining <= 90)
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Exposure ↔ Portfolio consistency warning ────────────────
            Consumer(builder: (context, ref, _) {
              final checkAsync = ref.watch(exposurePortfolioCheckProvider);
              return checkAsync.maybeWhen(
                data: (check) {
                  if (check == null || check.isConsistent) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Unrealized exposure total (\u20b9${check.exposureTotal.toStringAsFixed(0)}) '
                            'deviates ${check.deviationPct.abs().toStringAsFixed(1)}% from portfolio '
                            '(\u20b9${check.portfolioTotal.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              );
            }),
            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.palette.bgCard, context.palette.bgCardElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.bgDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unrealized Gain / Loss',
                      style: TextStyle(
                          color: context.palette.textSecondary, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    totalGain.toINRCompact(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: totalGain >= 0
                          ? context.palette.gain
                          : context.palette.loss,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ExposureChip(
                          'Est. Tax if Sold Today',
                          totalTax.toINRCompact(),
                          context.palette.loss),
                      if (soonCount > 0) ...[
                        const SizedBox(width: 12),
                        _ExposureChip(
                            'STCG\u2192LTCG Soon',
                            '$soonCount funds',
                            AppColors.warning),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Sort bar ───────────────────────────────────────────────
            Row(
              children: [
                Text(
                  '${exposures.length} fund${exposures.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 12, color: context.palette.textTertiary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: context.palette.bgDivider, width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_ExposureSort>(
                        value: _sort,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.sort, size: 14),
                        style: TextStyle(
                            fontSize: 11, color: context.palette.textSecondary),
                        items: _ExposureSort.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _sort = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Per-fund cards
            ...exposures.map((e) => _ExposureCard(exposure: e)),
          ],
        );
      },
    );
  }
}

class _ExposureChip extends StatelessWidget {
  const _ExposureChip(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10, color: context.palette.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

class _ExposureCard extends StatefulWidget {
  const _ExposureCard({required this.exposure});
  final UnrealizedExposure exposure;

  @override
  State<_ExposureCard> createState() => _ExposureCardState();
}

class _ExposureCardState extends State<_ExposureCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.exposure;
    final isProfit = e.unrealisedGain >= 0;
    final gainColor = isProfit ? context.palette.gain : context.palette.loss;
    final gainPct = e.costBasis > 0
        ? (e.unrealisedGain / e.costBasis) * 100
        : 0.0;

    // Badge color for gain type
    Color badgeColor;
    switch (e.gainType) {
      case 'LTCG':
        badgeColor = context.palette.gain;
        break;
      case 'STCG':
        badgeColor = AppColors.warning;
        break;
      default:
        badgeColor = AppColors.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fund name + gain type badge
                Row(
                  children: [
                    Expanded(
                      child: Text(e.fundName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(e.gainType,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(e.memberName,
                    style: TextStyle(
                        fontSize: 11, color: context.palette.textTertiary)),
                const SizedBox(height: 6),

                // ── Investor details row ──
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (e.investedSince != null)
                      _DetailChip(Icons.calendar_today_outlined,
                          'Since ${e.investedSince!.displayDate}'),
                    _DetailChip(Icons.schedule_outlined,
                        e.holdingPeriodFormatted),
                    if (e.planType != null)
                      _DetailChip(
                          e.planType == 'Direct'
                              ? Icons.bolt_outlined
                              : Icons.storefront_outlined,
                          e.planType!,
                          color: _planChipColor(e.planType)),
                    _DetailChip(Icons.category_outlined,
                        e.taxCategoryLabel,
                        color: _taxCatChipColor(context, e.taxCategory)),
                    if (e.expenseRatio != null)
                      _DetailChip(Icons.percent_outlined,
                          'ER ${e.expenseRatio!.toStringAsFixed(2)}%'),
                    if (e.return1y != null)
                      _DetailChip(
                          e.return1y! >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          '1Y ${e.return1y! >= 0 ? '+' : ''}${e.return1y!.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 8),

                // Invested → Current → Gain row
                Row(
                  children: [
                    _ExposureStat('Invested', e.costBasis.toINRCompact(),
                        context.palette.textSecondary),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward,
                          size: 10, color: context.palette.textTertiary),
                    ),
                    _ExposureStat('Current', e.currentValue.toINRCompact(),
                        context.palette.textPrimary),
                    const SizedBox(width: 12),
                    _ExposureStat(
                      'Gain',
                      '${isProfit ? '\u2191' : '\u2193'}${e.unrealisedGain.toINRCompact()} '
                          '(${gainPct >= 0 ? '+' : ''}${gainPct.toStringAsFixed(1)}%)',
                      gainColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _ExposureStat('Est. Tax', e.estimatedTax.toINRCompact(),
                        context.palette.loss),
                    const SizedBox(width: 16),
                    _ExposureStat('Units', e.totalUnits.toStringAsFixed(2),
                        context.palette.textSecondary),
                  ],
                ),

                // LTCG countdown
                if (e.ltcgDaysRemaining > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${e.ltcgDaysRemaining} days to LTCG '
                          '(lower tax rate)',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.warning),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── "What if I Redeemed Today?" toggle ──
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded ? Icons.calculate : Icons.calculate_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expanded ? 'Hide Redemption Details  \u25B2' : 'What if I Redeemed Today?  \u25BC',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Expanded "What if I Redeemed Today?" section ──
          if (_expanded) ...[
            const Divider(height: 1),
            _WhatIfRedemptionSection(exposure: e),
          ],
        ],
      ),
    );
  }
}

/// "What if I Redeemed Today?" expandable section
class _WhatIfRedemptionSection extends StatelessWidget {
  const _WhatIfRedemptionSection({required this.exposure});
  final UnrealizedExposure exposure;

  @override
  Widget build(BuildContext context) {
    final e = exposure;
    final hasStcg = e.stcgGain.abs() > 0.01;
    final hasLtcg = e.ltcgGain.abs() > 0.01;
    final totalGain = e.unrealisedGain;
    final isProfit = totalGain >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'What if I Redeemed Today?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Gains breakdown ──
          _WhatIfRow(
            icon: Icons.trending_up,
            iconColor: isProfit ? context.palette.gain : context.palette.loss,
            label: 'Gains',
            value: totalGain.toINRCompact(),
            valueColor: isProfit ? context.palette.gain : context.palette.loss,
            isBold: true,
          ),
          if (hasStcg) ...[
            const SizedBox(height: 4),
            _WhatIfSubRow(
              label: 'Short Term Gains',
              value: e.stcgGain.toINRCompact(),
              valueColor: e.stcgGain >= 0 ? context.palette.gain : context.palette.loss,
              taxRate: '@ ${(e.stcgTaxRate * 100).toStringAsFixed(0)}%',
            ),
          ],
          if (hasLtcg) ...[
            const SizedBox(height: 4),
            _WhatIfSubRow(
              label: 'Long Term Gains',
              value: e.ltcgGain.toINRCompact(),
              valueColor: e.ltcgGain >= 0 ? context.palette.gain : context.palette.loss,
              taxRate: '@ ${(e.ltcgTaxRate * 100).toStringAsFixed(1)}%',
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Tax breakdown ──
          _WhatIfRow(
            icon: Icons.account_balance,
            iconColor: context.palette.loss,
            label: 'Total Tax',
            value: e.estimatedTax.toINRCompact(),
            valueColor: context.palette.loss,
            isBold: true,
          ),
          if (hasStcg && e.stcgTax > 0) ...[
            const SizedBox(height: 4),
            _WhatIfSubRow(
              label: 'STCG Tax',
              value: e.stcgTax.toINRCompact(),
              valueColor: context.palette.loss,
            ),
          ],
          if (hasLtcg && e.ltcgTax > 0) ...[
            const SizedBox(height: 4),
            _WhatIfSubRow(
              label: 'LTCG Tax',
              value: e.ltcgTax.toINRCompact(),
              valueColor: context.palette.loss,
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Post-tax gains ──
          _WhatIfRow(
            icon: Icons.savings_outlined,
            iconColor: e.postTaxGain >= 0 ? context.palette.gain : context.palette.loss,
            label: 'Post Tax Gains',
            value: e.postTaxGain.toINRCompact(),
            valueColor: e.postTaxGain >= 0 ? context.palette.gain : context.palette.loss,
            isBold: true,
          ),

          // ── Exit load ──
          if (e.exitLoadAmount > 0.01) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _WhatIfRow(
              icon: Icons.exit_to_app,
              iconColor: AppColors.warning,
              label: 'Exit Load',
              value: e.exitLoadAmount.toINRCompact(),
              valueColor: AppColors.warning,
              isBold: true,
            ),
            const SizedBox(height: 4),
            _WhatIfSubRow(
              label: 'Current Value',
              value: e.currentValue.toINRCompact(),
              valueColor: context.palette.textSecondary,
            ),
            if (e.exitLoadText != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  e.exitLoadText!,
                  style: TextStyle(
                    fontSize: 9,
                    color: context.palette.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ] else if (e.exitLoadText != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _WhatIfRow(
              icon: Icons.exit_to_app,
              iconColor: context.palette.gain,
              label: 'Exit Load',
              value: 'Nil',
              valueColor: context.palette.gain,
              isBold: true,
            ),
          ],

          // ── Net in-hand amount ──
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (e.postTaxGain >= 0 ? context.palette.gain : context.palette.loss)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (e.postTaxGain >= 0 ? context.palette.gain : context.palette.loss)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'You would receive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textSecondary,
                  ),
                ),
                Text(
                  (e.currentValue - e.estimatedTax - e.exitLoadAmount).toINRCompact(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row for "What if" section — icon + label + value
class _WhatIfRow extends StatelessWidget {
  const _WhatIfRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: context.palette.textSecondary,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            )),
      ],
    );
  }
}

/// Sub-row (indented) for breakdowns
class _WhatIfSubRow extends StatelessWidget {
  const _WhatIfSubRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.taxRate,
  });
  final String label;
  final String value;
  final Color valueColor;
  final String? taxRate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textTertiary,
                    )),
                if (taxRate != null) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: context.palette.textTertiary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(taxRate!,
                        style: TextStyle(
                          fontSize: 9,
                          color: context.palette.textTertiary,
                        )),
                  ),
                ],
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}

class _ExposureStat extends StatelessWidget {
  const _ExposureStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: context.palette.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.icon, this.text, {this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: c),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, color: c)),
        ],
      ),
    );
  }
}

Color _taxCatChipColor(BuildContext context, TaxCategory tc) {
  switch (tc) {
    case TaxCategory.equity:
      return const Color(0xFF1B8A5A); // green
    case TaxCategory.hybridE:
      return const Color(0xFF3B82F6); // blue
    case TaxCategory.hybridD:
      return const Color(0xFF8B5CF6); // violet
    case TaxCategory.debt:
      return const Color(0xFF8B5CF6); // violet
    case TaxCategory.goldEtf:
      return const Color(0xFFF59E0B); // amber
    default:
      return context.palette.textTertiary;
  }
}

Color _planChipColor(String? planType) {
  if (planType == 'Direct') return const Color(0xFF1B8A5A); // green
  return const Color(0xFFF59E0B); // amber for Regular
}

// ─── Harvest sort options ────────────────────────────────────────────────────
enum _GainHarvestSort {
  savingDesc('Tax Saving: High \u2192 Low'),
  gainDesc('Gain: High \u2192 Low'),
  gainPctDesc('Gain %: High \u2192 Low'),
  nameAsc('Fund: A \u2192 Z');

  const _GainHarvestSort(this.label);
  final String label;
}

enum _LossHarvestSort {
  lossDesc('Loss: High \u2192 Low'),
  lossPctDesc('Loss %: High \u2192 Low'),
  holdingAsc('Holding: Shortest First'),
  nameAsc('Fund: A \u2192 Z');

  const _LossHarvestSort(this.label);
  final String label;
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 3: Harvest (Gain + Loss Harvest + Tax Planning Tips)
// ══════════════════════════════════════════════════════════════════════════════
class _HarvestTab extends ConsumerStatefulWidget {
  const _HarvestTab({this.selectedMemberId});
  final String? selectedMemberId;

  @override
  ConsumerState<_HarvestTab> createState() => _HarvestTabState();
}

class _HarvestTabState extends ConsumerState<_HarvestTab> {
  _GainHarvestSort _gainSort = _GainHarvestSort.savingDesc;
  _LossHarvestSort _lossSort = _LossHarvestSort.lossDesc;

  void _applySortGain(List<HarvestOpportunity> list) {
    switch (_gainSort) {
      case _GainHarvestSort.savingDesc:
        list.sort(
            (a, b) => b.potentialTaxSaving.compareTo(a.potentialTaxSaving));
      case _GainHarvestSort.gainDesc:
        list.sort((a, b) => b.unrealisedGain.compareTo(a.unrealisedGain));
      case _GainHarvestSort.gainPctDesc:
        list.sort((a, b) => b.gainPct.compareTo(a.gainPct));
      case _GainHarvestSort.nameAsc:
        list.sort((a, b) =>
            a.fundName.toLowerCase().compareTo(b.fundName.toLowerCase()));
    }
  }

  void _applySortLoss(List<LossHarvestOpportunity> list) {
    switch (_lossSort) {
      case _LossHarvestSort.lossDesc:
        list.sort((a, b) => b.unrealisedLoss.compareTo(a.unrealisedLoss));
      case _LossHarvestSort.lossPctDesc:
        list.sort((a, b) => b.lossPct.compareTo(a.lossPct));
      case _LossHarvestSort.holdingAsc:
        list.sort((a, b) => a.holdingDays.compareTo(b.holdingDays));
      case _LossHarvestSort.nameAsc:
        list.sort((a, b) =>
            a.fundName.toLowerCase().compareTo(b.fundName.toLowerCase()));
    }
  }

  Widget _buildSortBar<T extends Enum>({
    required int count,
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Text(
          '$count $label${count == 1 ? '' : 's'}',
          style:
              TextStyle(fontSize: 12, color: context.palette.textTertiary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.palette.bgDivider, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                isExpanded: true,
                icon: const Icon(Icons.sort, size: 14),
                style: TextStyle(
                    fontSize: 11, color: context.palette.textSecondary),
                items: values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(labelOf(s)),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final harvestAsync = ref.watch(taxHarvestOpportunitiesProvider);

    final camsData = ref.watch(camsTaxStatementProvider).valueOrNull?.forMember(widget.selectedMemberId);

    return harvestAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (fullResult) {
        // Filter by selected member
        final gainOpps = widget.selectedMemberId == null
            ? [...fullResult.opportunities]
            : fullResult.opportunities
                .where((o) => o.memberId == widget.selectedMemberId)
                .toList();
        final lossOpps = widget.selectedMemberId == null
            ? [...fullResult.lossOpportunities]
            : fullResult.lossOpportunities
                .where((l) => l.memberId == widget.selectedMemberId)
                .toList();

        // Apply sorting
        _applySortGain(gainOpps);
        _applySortLoss(lossOpps);

        final result = HarvestResult(
          opportunities: gainOpps,
          totalPotentialSaving:
              gainOpps.fold(0.0, (s, o) => s + o.potentialTaxSaving),
          lossOpportunities: lossOpps,
          totalOffsettableLoss:
              lossOpps.fold(0.0, (s, l) => s + l.unrealisedLoss),
          unusedExemptionPerMember: fullResult.unusedExemptionPerMember,
        );

        final hasGainOpps = result.opportunities.isNotEmpty;
        final hasLossOpps = result.lossOpportunities.isNotEmpty;

        // ── Booked LTCG from CAMS verified data (per-lot for accuracy) ──
        final bookedLtcg = camsData != null && camsData.hasData
            ? camsData.perLotGains.eqLtcg
            : 0.0;
        final exemptionLimit = AppConstants.ltcgExemptionPerPersonPerFy;
        final remainingExemption =
            (exemptionLimit - bookedLtcg).clamp(0.0, exemptionLimit);

        if (!hasGainOpps && !hasLossOpps) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (bookedLtcg > 0)
                _BookedLtcgBanner(
                    booked: bookedLtcg, remaining: remainingExemption),
              if (bookedLtcg > 0) const SizedBox(height: 12),
              _NoHarvestPlaceholder(),
              const SizedBox(height: 16),
              const _LossOffsetRulesCard(),
              const SizedBox(height: 16),
              const _TaxPlanningTipsCard(),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Booked LTCG from registrar ──
            if (bookedLtcg > 0) ...[
              _BookedLtcgBanner(
                  booked: bookedLtcg, remaining: remainingExemption),
              const SizedBox(height: 12),
            ],

            // ── LTCG Gain Harvesting Summary ──
            if (hasGainOpps) ...[
              _GainHarvestSummary(
                totalSaving: result.totalPotentialSaving,
                count: result.opportunities.length,
              ),
              const SizedBox(height: 8),
              _buildSortBar<_GainHarvestSort>(
                count: gainOpps.length,
                label: 'opportunity',
                value: _gainSort,
                values: _GainHarvestSort.values,
                labelOf: (s) => s.label,
                onChanged: (v) {
                  if (v != null) setState(() => _gainSort = v);
                },
              ),
              const SizedBox(height: 8),
              ...result.opportunities
                  .map((o) => _GainHarvestCard(opportunity: o)),
              const SizedBox(height: 16),
            ],

            // ── Loss Harvesting ──
            if (hasLossOpps) ...[
              _LossHarvestSummary(
                totalLoss: result.totalOffsettableLoss,
                count: result.lossOpportunities.length,
              ),
              const SizedBox(height: 8),
              _buildSortBar<_LossHarvestSort>(
                count: lossOpps.length,
                label: 'fund',
                value: _lossSort,
                values: _LossHarvestSort.values,
                labelOf: (s) => s.label,
                onChanged: (v) {
                  if (v != null) setState(() => _lossSort = v);
                },
              ),
              const SizedBox(height: 8),
              ...result.lossOpportunities
                  .map((l) => _LossHarvestCard(loss: l)),
              const SizedBox(height: 16),
            ],

            // ── Loss Offset Rules ──
            const _LossOffsetRulesCard(),
            const SizedBox(height: 16),

            // ── Tax Planning Tips ──
            const _TaxPlanningTipsCard(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _BookedLtcgBanner extends StatelessWidget {
  const _BookedLtcgBanner({required this.booked, required this.remaining});
  final double booked;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final limit = AppConstants.ltcgExemptionPerPersonPerFy;
    final usedPct = (booked / limit).clamp(0.0, 1.0);
    final exhausted = remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: exhausted
            ? context.palette.loss.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exhausted
              ? context.palette.loss.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified,
                  size: 16,
                  color: exhausted ? context.palette.loss : AppColors.primary),
              const SizedBox(width: 6),
              Text('LTCG Exemption Status (Registrar Verified)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usedPct,
              minHeight: 8,
              backgroundColor: context.palette.textTertiary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                  exhausted ? context.palette.loss : AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booked.toINRCompact()} booked',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: exhausted ? context.palette.loss : AppColors.primary),
              ),
              Text(
                'of ${limit.toINRCompact()} limit',
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            exhausted
                ? 'Exemption fully used. Additional equity LTCG will be taxed at 12.5%.'
                : '${remaining.toINRCompact()} remaining \u2014 you can book more equity LTCG tax-free this FY.',
            style: TextStyle(
              fontSize: 11,
              color: exhausted ? context.palette.loss : context.palette.gain,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHarvestPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 48, color: context.palette.gain),
          const SizedBox(height: 12),
          Text('No harvest opportunities found',
              style: TextStyle(
                  color: context.palette.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Equity LTCG harvest is available when you have '
              'unrealised gains that can be booked tax-free under '
              '\u20b91.25L exemption.\n\n'
              'Loss harvest is available when you have funds at a loss '
              'that can be sold to offset realised gains.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textTertiary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gain Harvest ────────────────────────────────────────────────────────────
class _GainHarvestSummary extends StatelessWidget {
  const _GainHarvestSummary({required this.totalSaving, required this.count});
  final double totalSaving;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.gain.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.gain.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, size: 16, color: context.palette.gain),
              const SizedBox(width: 6),
              Text('LTCG Gain Harvesting',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.palette.gain)),
              const Spacer(),
              Text(
                'Save up to ${totalSaving.toINRCompact()}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.palette.gain),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Book equity gains up to \u20b91.25L each FY tax-free. '
            'Sell funds held >1 year and re-buy next day to reset cost basis. '
            '$count fund${count > 1 ? 's' : ''} eligible.',
            style: TextStyle(
                fontSize: 11,
                color: context.palette.textSecondary,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _GainHarvestCard extends StatelessWidget {
  const _GainHarvestCard({required this.opportunity});
  final HarvestOpportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final o = opportunity;
    final holdingYears = (o.holdingDays / 365).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Fund name + LTCG badge ──
            Row(
              children: [
                Expanded(
                  child: Text(o.fundName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.palette.gain.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('LTCG',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.palette.gain)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // ── Row 2: Member · Holding period · Units ──
            Text(
              '${o.memberName}  \u00b7  Held ${holdingYears}y  \u00b7  ${o.units.toStringAsFixed(0)} units',
              style: TextStyle(
                  fontSize: 11, color: context.palette.textTertiary),
            ),
            const SizedBox(height: 10),

            // ── Row 3: Key metrics in a clean grid ──
            Row(
              children: [
                Expanded(
                    child: _HarvestStat('Invested',
                        o.investedAmount.toINRCompact(), context.palette.textSecondary)),
                Expanded(
                    child: _HarvestStat('Current Value',
                        o.currentValue.toINRCompact(), context.palette.textPrimary)),
                Expanded(
                  child: _HarvestStat(
                    'Unrealised Gain',
                    '${o.unrealisedGain.toINRCompact()} (+${o.gainPct.toStringAsFixed(1)}%)',
                    context.palette.gain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 4: Harvest suggestion — compact action box ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Redeem '),
                            TextSpan(
                              text:
                                  '${o.unitsToRedeem.toStringAsFixed(0)} units (${o.amountToRedeem.toINRCompact()})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Books ${o.ltcgGainToBook.toINRCompact()} LTCG tax-free  \u00b7  Saves ${o.potentialTaxSaving.toINRCompact()} tax',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.palette.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Re-buy next day \u2014 no wash sale rule for MFs in India',
                          style: TextStyle(
                              fontSize: 9,
                              color: context.palette.textTertiary,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Exit load warning ──
            if (o.exitLoadAmount > 0.01) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exit load: ${o.exitLoadPct?.toStringAsFixed(2) ?? "1.00"}% '
                        '(${o.exitLoadAmount.toINRCompact()}) applies — '
                        'held < ${o.exitLoadDays ?? 365} days',
                        style: TextStyle(fontSize: 10, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (o.exitLoadDays != null && o.exitLoadPct != null) ...[
              const SizedBox(height: 4),
              Text(
                'No exit load \u2014 held > ${o.exitLoadDays} days',
                style: TextStyle(fontSize: 9, color: context.palette.gain, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Loss Harvest ────────────────────────────────────────────────────────────
class _LossHarvestSummary extends StatelessWidget {
  const _LossHarvestSummary({required this.totalLoss, required this.count});
  final double totalLoss;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.loss.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.loss.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, size: 16, color: context.palette.loss),
              const SizedBox(width: 6),
              Text('Loss Harvesting',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.palette.loss)),
              const Spacer(),
              Text(
                '\u20b9${totalLoss.toStringAsFixed(0)} offsettable',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.palette.loss),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Book unrealised losses to offset realised capital gains and reduce tax. '
            '$count fund${count > 1 ? 's' : ''} at a loss.',
            style: TextStyle(
                fontSize: 11,
                color: context.palette.textSecondary,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LossHarvestCard extends StatelessWidget {
  const _LossHarvestCard({required this.loss});
  final LossHarvestOpportunity loss;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fund name + STCG/LTCG badge
            Row(
              children: [
                Expanded(
                  child: Text(loss.fundName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (loss.isLongTerm ? AppColors.warning : context.palette.loss)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(loss.isLongTerm ? 'LT Loss' : 'ST Loss',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: loss.isLongTerm
                              ? AppColors.warning
                              : context.palette.loss)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(loss.memberName,
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary)),
            const SizedBox(height: 10),

            // Invested → Current → Loss
            Row(
              children: [
                _HarvestStat(
                    'Invested', loss.investedAmount.toINRCompact(),
                    context.palette.textSecondary),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward,
                      size: 10, color: context.palette.textTertiary),
                ),
                _HarvestStat(
                    'Current', loss.currentValue.toINRCompact(),
                    context.palette.textPrimary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loss',
                        style: TextStyle(
                            fontSize: 9, color: context.palette.textTertiary)),
                    Row(
                      children: [
                        Icon(Icons.arrow_downward,
                            size: 10, color: context.palette.loss),
                        Text(
                          '-${loss.unrealisedLoss.toINRCompact()} '
                          '(-${loss.lossPct.toStringAsFixed(1)}%)',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.palette.loss),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Offset info box
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.info),
                      const SizedBox(width: 6),
                      Text(loss.offsetAbility,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loss.isLongTerm
                        ? 'Long-term loss can only offset long-term capital gains (Equity/Gold LTCG). '
                          'Cannot offset short-term gains or debt gains.'
                        : 'Short-term loss can offset ALL capital gains \u2014 '
                          'both STCG and LTCG from any asset class.',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.palette.textSecondary,
                        height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sell & re-buy next day to book loss while staying invested',
                    style: TextStyle(
                        fontSize: 10,
                        color: context.palette.textTertiary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                _HarvestStat(
                    'Holding',
                    '${(loss.holdingDays / 365).toStringAsFixed(1)}y',
                    context.palette.textSecondary),
                const SizedBox(width: 16),
                _HarvestStat(
                    'Units', loss.units.toStringAsFixed(2),
                    context.palette.textSecondary),
                const SizedBox(width: 16),
                _HarvestStat(
                    'NAV', '\u20b9${loss.currentNav.toStringAsFixed(2)}',
                    context.palette.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loss Offset Rules Card ──────────────────────────────────────────────────
class _LossOffsetRulesCard extends StatelessWidget {
  const _LossOffsetRulesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              const Text('Capital Loss Offset Rules (IT Act Sec 70-71)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info)),
            ],
          ),
          const SizedBox(height: 10),
          _RuleRow(
            icon: Icons.check_circle,
            color: context.palette.gain,
            text: 'Short-term loss can offset both STCG and LTCG',
          ),
          _RuleRow(
            icon: Icons.warning_amber,
            color: AppColors.warning,
            text: 'Long-term loss can only offset LTCG (not STCG)',
          ),
          _RuleRow(
            icon: Icons.history,
            color: AppColors.info,
            text: 'Unabsorbed loss carries forward for 8 assessment years',
          ),
          _RuleRow(
            icon: Icons.calendar_today,
            color: context.palette.textSecondary,
            text: 'File ITR before due date to carry forward losses',
          ),
          _RuleRow(
            icon: Icons.check,
            color: context.palette.gain,
            text: 'No wash sale rule for MFs in India \u2014 re-buy immediately is allowed',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textSecondary,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}

// ── Tax Planning Tips Card ──────────────────────────────────────────────────
class _TaxPlanningTipsCard extends StatefulWidget {
  const _TaxPlanningTipsCard();

  @override
  State<_TaxPlanningTipsCard> createState() => _TaxPlanningTipsCardState();
}

class _TaxPlanningTipsCardState extends State<_TaxPlanningTipsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Smart Tax Planning Strategies',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable tips
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: const [
                  _TipCard(
                    number: '1',
                    title: 'Hold > 12 Months for Lower Tax',
                    description:
                        'Equity LTCG (>12m) is taxed at 12.5% vs STCG at 20%. '
                        'Check the Unrealized tab for funds approaching LTCG threshold.',
                    icon: Icons.timer,
                  ),
                  _TipCard(
                    number: '2',
                    title: 'Use \u20b91.25L Annual LTCG Exemption',
                    description:
                        'Each family member gets \u20b91.25L equity LTCG exemption per FY. '
                        'Book gains within this limit tax-free. See gain harvest suggestions above.',
                    icon: Icons.savings,
                  ),
                  _TipCard(
                    number: '3',
                    title: 'Tax-Loss Harvesting',
                    description:
                        'Sell underperforming funds at loss to offset gains. Short-term '
                        'losses are more valuable as they offset both STCG & LTCG. '
                        'Re-buy next day to stay invested.',
                    icon: Icons.trending_down,
                  ),
                  _TipCard(
                    number: '4',
                    title: 'Prefer Growth over IDCW',
                    description:
                        'IDCW (dividends) are taxed at your full slab rate. Growth '
                        'plans defer tax until redemption, and equity gains get the '
                        'lower 12.5% LTCG rate.',
                    icon: Icons.show_chart,
                  ),
                  _TipCard(
                    number: '5',
                    title: 'Plan Redemptions Around FY End',
                    description:
                        'Sell before March 31 to book gains in current FY (using '
                        'remaining exemption). Or defer to April 1 to push gains '
                        'to next FY with fresh \u20b91.25L exemption.',
                    icon: Icons.calendar_month,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
  final String number;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(number,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.palette.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HarvestStat extends StatelessWidget {
  const _HarvestStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9, color: context.palette.textTertiary)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

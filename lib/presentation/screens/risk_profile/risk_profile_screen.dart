import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/risk_tiers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/risk_profile_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/member_selector.dart';
import '../../widgets/risk_profile/equity_debt_slider.dart';
import '../../widgets/risk_profile/risk_meter.dart';
import '../../widgets/risk_profile/risk_profile_banner.dart';

class RiskProfileScreen extends ConsumerStatefulWidget {
  const RiskProfileScreen({super.key});

  @override
  ConsumerState<RiskProfileScreen> createState() => _RiskProfileScreenState();
}

class _RiskProfileScreenState extends ConsumerState<RiskProfileScreen> {
  String? _selectedMemberId; // null = ALL
  List<FamilyMemberModel> _members = const [];

  // Per-tab drafts keyed by memberId ('' for ALL).
  final Map<String, RiskTier?> _draftTier = {};
  final Map<String, double?> _draftEquity = {};

  String _key(String? memberId) => memberId ?? '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final familyAsync = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Profile')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          _members = members;

          return familyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (family) {
              if (family == null) {
                return const Center(child: Text('Add a family member first.'));
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: MemberSelector(
                      selectedMemberId: _selectedMemberId,
                      onSelected: (id) {
                        setState(() => _selectedMemberId = id);
                        ref
                            .read(selectedRiskMemberProvider.notifier)
                            .select(id);
                      },
                    ),
                  ),
                  Expanded(
                    child: _selectedMemberId == null
                        ? _buildAllTab(family)
                        : _buildMemberTab(
                            family,
                            members.firstWhere(
                                (m) => m.id == _selectedMemberId),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAllTab(FamilyModel family) {
    final k = _key(null);
    final tier = _draftTier[k] ?? RiskTier.fromDb(family.riskProfile);
    final equity = _draftEquity[k] ?? family.riskTargetEquityPct;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: SwitchListTile(
            value: family.riskFamilyEnabled,
            onChanged: (v) => ref
                .read(riskProfileMutatorProvider.notifier)
                .toggleFamilyEnabled(v),
            title: const Text('Use family-level risk profile'),
            subtitle: const Text(
                'When ON, this profile applies to the whole family. When OFF, each member uses their own.'),
          ),
        ),
        const SizedBox(height: 16),
        ..._buildCommonControls(context, 
          memberId: null,
          currentTier: tier,
          currentEquity: equity,
          source: family.riskProfileSource,
          finalScore: null,
        ),
      ],
    );
  }

  Widget _buildMemberTab(FamilyModel family, FamilyMemberModel m) {
    final k = _key(m.id);
    final tier = _draftTier[k] ?? RiskTier.fromDb(m.riskProfile);
    final equity = _draftEquity[k] ?? m.riskTargetEquityPct;
    final disabled = family.riskFamilyEnabled;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (disabled)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Text(
              'Family-level profile is ON — this member inherits the family profile. Switch to "All" and turn it off to edit individually.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ..._buildCommonControls(context, 
          memberId: m.id,
          currentTier: tier,
          currentEquity: equity,
          source: m.riskProfileSource,
          finalScore: m.riskFinalScore,
          disabled: disabled,
        ),
      ],
    );
  }

  List<Widget> _buildCommonControls(BuildContext context, {
    required String? memberId,
    required RiskTier currentTier,
    required double currentEquity,
    required String source,
    required int? finalScore,
    bool disabled = false,
  }) {
    final k = _key(memberId);
    final hasDraft = _draftTier[k] != null || _draftEquity[k] != null;

    return [
      DropdownButtonFormField<RiskTier>(
        initialValue: currentTier,
        decoration: const InputDecoration(
          labelText: 'Your risk vibe',
          border: OutlineInputBorder(),
        ),
        items: RiskTier.values
            .map((t) => DropdownMenuItem(value: t, child: Text(t.dbValue)))
            .toList(),
        onChanged: disabled
            ? null
            : (t) {
                if (t == null) return;
                setState(() {
                  _draftTier[k] = t;
                  _draftEquity[k] = t.defaultEquity.toDouble();
                });
              },
      ),
      const SizedBox(height: 16),
      EquityDebtSlider(
        equityPct: currentEquity,
        onChanged: disabled
            ? (_) {}
            : (v) => setState(() {
                  _draftEquity[k] = v;
                  _draftTier[k] ??= currentTier;
                }),
      ),
      const SizedBox(height: 16),
      RiskProfileBanner(tier: currentTier, source: source, finalScore: finalScore),
      const SizedBox(height: 16),
      Center(child: RiskMeter(tier: currentTier)),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: disabled
            ? null
            : () => context.push(
                  Routes.riskQuestionnaire,
                  extra: {'memberId': memberId},
                ),
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('Find My Risk Appetite (2 min quiz)'),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: disabled || !hasDraft
                  ? null
                  : () => setState(() {
                        _draftTier.remove(k);
                        _draftEquity.remove(k);
                      }),
              child: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: disabled || !hasDraft
                  ? null
                  : () async {
                      final saveTier = _draftTier[k] ?? currentTier;
                      final saveEq = _draftEquity[k] ?? currentEquity;
                      try {
                        await ref
                            .read(riskProfileMutatorProvider.notifier)
                            .saveManual(
                              memberId: memberId,
                              tier: saveTier,
                              equityPct: saveEq,
                              debtPct: 100 - saveEq,
                            );
                        if (!mounted) return;
                        setState(() {
                          _draftTier.remove(k);
                          _draftEquity.remove(k);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved!')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save failed: $e')),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        'Disclaimer: This is purely a mathematical calculation based on the inputs set by you above. Returns are neither assured nor guaranteed. Please consult your financial advisor before taking any investment decisions.',
        style:
            TextStyle(fontSize: 10, color: context.palette.textTertiary, height: 1.4),
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/risk_tiers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../providers/family_provider.dart';
import '../../router/route_names.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _relationships = [
  'Self', 'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'HUF', 'Other'
];
const _uniqueRelationships = {'Self', 'Spouse'};

// Derived from the canonical RiskTier enum to stay in sync with the
// risk profiling feature. Drop-down values are the DB strings.
final _riskProfiles = RiskTier.values.map((t) => t.dbValue).toList();

const _taxSlabs = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];

const _investmentGoals = [
  'Retirement',
  "Child's Education",
  "Child's Marriage",
  'Wealth Building',
  'Home Purchase',
  'Income Generation',
  'Capital Preservation',
  'Emergency Fund',
];

// ─── Helpers ─────────────────────────────────────────────────────────────────

int? _computeAge(String? dob) {
  if (dob == null || dob.isEmpty) return null;
  final d = DateTime.tryParse(dob);
  if (d == null) return null;
  final now = DateTime.now();
  int age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  return age;
}

String _horizonFromAge(int? age) {
  if (age == null) return '';
  if (age < 35) return '25+ yrs (Long)';
  if (age < 50) return '10-25 yrs (Medium)';
  if (age < 60) return '5-15 yrs (Short-Medium)';
  return '<10 yrs (Short)';
}

Color _riskColor(String? risk) => RiskTier.fromDb(risk).color;

// ─── Screen ──────────────────────────────────────────────────────────────────

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          // Sort: Self first, Spouse second, then alphabetical
          final sorted = [...members]..sort((a, b) {
              const order = {'Self': 0, 'Spouse': 1};
              final oa = order[a.relationship] ?? 2;
              final ob = order[b.relationship] ?? 2;
              if (oa != ob) return oa.compareTo(ob);
              return a.displayName.compareTo(b.displayName);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _EntryCard(
                icon: Icons.shield_outlined,
                title: 'Risk Profile',
                subtitle:
                    'Profile risk appetite for ALL members or individually',
                color: AppColors.primary,
                onTap: () => context.push(Routes.riskProfile),
              ),
              const SizedBox(height: 10),
              _EntryCard(
                icon: Icons.flag_outlined,
                title: 'Goals',
                subtitle:
                    'Individual and family goals (car, home, retirement)',
                color: Colors.purple,
                onTap: () => context.push(Routes.goalLanding),
              ),
              const SizedBox(height: 20),
              const _SectionHeader('MEMBERS'),
              ...sorted.map((m) => _MemberCard(
                    member: m,
                    onTap: () => _openEditPage(context, m, members),
                  )),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openAddPage(context, members),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Add Member'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _refreshAfterSave() {
    ref.invalidate(familyMembersProvider);
    ref.invalidate(selfMemberProvider);
    ref.invalidate(currentProfileProvider);
  }

  void _openAddPage(
      BuildContext context, List<FamilyMemberModel> existingMembers) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MemberEditPage(
        existingMembers: existingMembers,
        onSaved: _refreshAfterSave,
      ),
    ));
  }

  void _openEditPage(BuildContext context, FamilyMemberModel member,
      List<FamilyMemberModel> existingMembers) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MemberEditPage(
        member: member,
        existingMembers: existingMembers,
        onSaved: _refreshAfterSave,
      ),
    ));
  }
}

// ─── Rich Member Card ────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});
  final FamilyMemberModel member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = member.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final age = _computeAge(member.dateOfBirth);
    final isSelf = member.relationship == 'Self';
    final borderColor =
        isSelf ? AppColors.primary : context.palette.bgDivider;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelf ? 1.5 : 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isSelf
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15),
                child: Text(initial,
                    style: TextStyle(
                        color: isSelf ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('CEO',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Subtitle line
                    Text(
                      [
                        if (member.relationship != null) member.relationship!,
                        if (age != null) '${age}y',
                        if (member.pan != null) member.pan!,
                      ].join(' \u2022 '),
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    // Chips row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (member.riskProfile.isNotEmpty)
                          _chip(member.riskProfile,
                              _riskColor(member.riskProfile)),
                        _chip('${member.taxSlabPct.toInt()}% slab',
                            AppColors.info),
                        _chip(
                            '${member.targetEquityPct.toInt()}/${member.targetDebtPct.toInt()}/${member.targetGoldPct.toInt()}',
                            context.palette.textTertiary),
                        if (member.investmentGoal != 'Wealth Building')
                          _chip(member.investmentGoal, Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: context.palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ─── Full-page Member Edit ───────────────────────────────────────────────────

class _MemberEditPage extends StatefulWidget {
  const _MemberEditPage({
    this.member,
    required this.existingMembers,
    required this.onSaved,
  });

  final FamilyMemberModel? member;
  final List<FamilyMemberModel> existingMembers;
  final VoidCallback onSaved;

  @override
  State<_MemberEditPage> createState() => _MemberEditPageState();
}

class _MemberEditPageState extends State<_MemberEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.member != null;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _eqCtrl;
  late final TextEditingController _debtCtrl;
  late final TextEditingController _goldCtrl;

  late double _driftThreshold;
  late final TextEditingController _driftCtrl;

  // Dropdown values
  late String _relationship;
  late String _riskProfile;
  late double _taxSlab;
  late String _investmentGoal;
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameCtrl = TextEditingController(text: m?.displayName ?? '');
    _panCtrl = TextEditingController(text: m?.pan ?? '');
    _emailCtrl = TextEditingController(text: m?.email ?? '');
    _mobileCtrl = TextEditingController(text: m?.mobile ?? '');
    _addressCtrl = TextEditingController(text: m?.address ?? '');
    _eqCtrl =
        TextEditingController(text: (m?.targetEquityPct ?? 60).toInt().toString());
    _debtCtrl =
        TextEditingController(text: (m?.targetDebtPct ?? 30).toInt().toString());
    _goldCtrl =
        TextEditingController(text: (m?.targetGoldPct ?? 10).toInt().toString());

    _relationship = m?.relationship ?? 'Self';
    // Guard against any pre-migration value that somehow sneaks through.
    _riskProfile = _riskProfiles.contains(m?.riskProfile)
        ? m!.riskProfile
        : 'Moderate';
    _taxSlab = m?.taxSlabPct ?? 30.0;
    _investmentGoal = m?.investmentGoal ?? 'Wealth Building';

    if (m?.dateOfBirth != null) {
      _dob = DateTime.tryParse(m!.dateOfBirth!);
    }
    _driftThreshold = m?.driftThresholdPct ?? 5.0;
    _driftCtrl = TextEditingController(text: _driftThreshold.toInt().toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _panCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _eqCtrl.dispose();
    _debtCtrl.dispose();
    _goldCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  bool _isRelationshipTaken(String rel) {
    if (!_uniqueRelationships.contains(rel)) return false;
    return widget.existingMembers
        .any((m) => m.relationship == rel && m.id != widget.member?.id);
  }

  int? get _age => _dob != null ? _computeAge(_dob!.toIso8601String()) : null;

  double get _allocationTotal {
    final eq = double.tryParse(_eqCtrl.text) ?? 0;
    final debt = double.tryParse(_debtCtrl.text) ?? 0;
    final gold = double.tryParse(_goldCtrl.text) ?? 0;
    return eq + debt + gold;
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final horizon = _horizonFromAge(age);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Member' : 'Add Family Member'),
        actions: [
          if (_isEditing && widget.member?.relationship != 'Self')
            IconButton(
              onPressed: (_saving || _deleting) ? null : _delete,
              icon: Icon(Icons.delete_outline, color: context.palette.loss),
              tooltip: 'Remove Member',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── IDENTITY ──
            _SectionHeader('Identity'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name *',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.family_restroom, size: 20),
              ),
              items: _relationships.map((r) {
                final taken = _isRelationshipTaken(r);
                return DropdownMenuItem(
                  value: r,
                  enabled: !taken,
                  child: Text(
                    taken ? '$r (already added)' : r,
                    style: TextStyle(
                        color: taken ? context.palette.textTertiary : null),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _relationship = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _panCtrl,
              decoration: const InputDecoration(
                labelText: 'PAN',
                prefixIcon: Icon(Icons.credit_card, size: 20),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            // DOB picker + Age input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DOB picker (left)
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _pickDob,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.cake_outlined, size: 20),
                        suffixIcon: Icon(Icons.calendar_today, size: 16),
                      ),
                      child: Text(
                        _dob != null
                            ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                            : 'Select',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dob != null
                              ? context.palette.textPrimary
                              : context.palette.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Age input (right) — alternative to DOB
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: age?.toString() ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      suffixText: 'yrs',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final a = int.tryParse(v);
                      if (a != null && a > 0 && a < 120) {
                        setState(() {
                          _dob = DateTime(
                              DateTime.now().year - a, 1, 1);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (age != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text('Investment Horizon: $horizon',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.primary)),
              ),
            const Divider(height: 32),

            // ── CONTACT ──
            _SectionHeader('Contact'),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                helperText: 'Auto-filled from CAMS CAS',
              ),
              maxLines: 2,
            ),
            const Divider(height: 32),

            // ── FINANCIAL PROFILE ──
            _SectionHeader('Financial Profile'),
            DropdownButtonFormField<double>(
              value: _taxSlab,
              decoration: const InputDecoration(
                labelText: 'Tax Slab',
                prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
              ),
              items: _taxSlabs
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.toInt()}%'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _taxSlab = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _riskProfiles.contains(_riskProfile)
                  ? _riskProfile
                  : 'Moderate',
              decoration: const InputDecoration(
                labelText: 'Risk Appetite',
                prefixIcon: Icon(Icons.speed, size: 20),
              ),
              items: _riskProfiles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _riskColor(r),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(r),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _riskProfile = v);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _investmentGoals.contains(_investmentGoal)
                  ? _investmentGoal
                  : 'Wealth Building',
              decoration: const InputDecoration(
                labelText: 'Investment Goal',
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
              ),
              items: _investmentGoals
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _investmentGoal = v);
              },
            ),
            const Divider(height: 32),

            // ── TARGET ALLOCATION ──
            _SectionHeader('Target Allocation'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _eqCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Equity %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _debtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Debt %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _goldCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Gold %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final total = _allocationTotal;
              final valid = (total - 100).abs() < 0.01;
              return Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (total / 100).clamp(0, 1),
                        backgroundColor: context.palette.bgDivider,
                        valueColor: AlwaysStoppedAnimation(
                            valid ? context.palette.gain : AppColors.warning),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${total.toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: valid ? context.palette.gain : context.palette.loss,
                    ),
                  ),
                  if (valid)
                    Padding(
                      padding: EdgeInsets.only(left: 4),
                      child:
                          Icon(Icons.check_circle, size: 14, color: context.palette.gain),
                    ),
                ],
              );
            }),

            const Divider(height: 32),

            // ── DRIFT THRESHOLD ──
            _SectionHeader('Rebalance Drift Threshold'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: _driftThreshold,
                        min: 3,
                        max: 15,
                        divisions: 12,
                        activeColor: AppColors.primary,
                        label: '${_driftThreshold.toInt()}%',
                        onChanged: (v) {
                          setState(() {
                            _driftThreshold = v;
                            _driftCtrl.text = v.toInt().toString();
                          });
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('3%', style: TextStyle(fontSize: 10, color: context.palette.textTertiary)),
                            Text('15%', style: TextStyle(fontSize: 10, color: context.palette.textTertiary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _driftCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Drift %',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null && val >= 3 && val <= 15) {
                        setState(() => _driftThreshold = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                'eVesh alerts you when any asset class drifts beyond this threshold from its ideal allocation.',
                style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
              ),
            ),

            const SizedBox(height: 32),
            // ── Save button ──
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: (_saving || _deleting) ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Save Changes' : 'Add Member',
                        style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _allocationTotal;
    if ((total - 100).abs() > 0.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Target allocation must sum to 100%'),
            backgroundColor: context.palette.loss),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser!.id;

      final data = {
        'display_name': _nameCtrl.text.trim(),
        'pan': _panCtrl.text.trim().isEmpty
            ? null
            : _panCtrl.text.trim().toUpperCase(),
        'relationship': _relationship,
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'mobile':
            _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        'address':
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'date_of_birth': _dob?.toIso8601String().substring(0, 10),
        'risk_profile': _riskProfile,
        'tax_slab_pct': _taxSlab,
        'investment_goal': _investmentGoal,
        'target_equity_pct': double.tryParse(_eqCtrl.text) ?? 60,
        'target_debt_pct': double.tryParse(_debtCtrl.text) ?? 30,
        'target_gold_pct': double.tryParse(_goldCtrl.text) ?? 10,
        'drift_threshold_pct': _driftThreshold,
      };

      if (_isEditing) {
        await supabase
            .from('family_members')
            .update(data)
            .eq('id', widget.member!.id);
      } else {
        // Get or create family (use limit(1) to handle duplicates safely)
        final existingFamilies = await supabase
            .from('families')
            .select('id')
            .eq('owner_id', uid)
            .order('created_at')
            .limit(1);

        String familyId;
        if ((existingFamilies as List).isEmpty) {
          final created = await supabase
              .from('families')
              .insert({'owner_id': uid, 'family_name': 'My Family'})
              .select('id')
              .single();
          familyId = created['id'] as String;
        } else {
          familyId = existingFamilies.first['id'] as String;
        }

        final createdMember = await supabase
            .from('family_members')
            .insert({
              ...data,
              'family_id': familyId,
              'owner_id': uid,
            })
            .select('id')
            .single();
        final newMemberId = createdMember['id'] as String;

        // Seed default long-term retirement goal at age 60.
        DateTime targetDate;
        if (_dob != null) {
          targetDate = DateTime(_dob!.year + 60, _dob!.month, _dob!.day);
          if (targetDate.isBefore(
              DateTime.now().add(const Duration(days: 365)))) {
            targetDate = DateTime.now().add(const Duration(days: 365 * 25));
          }
        } else {
          targetDate = DateTime.now().add(const Duration(days: 365 * 25));
        }
        try {
          await supabase.from('goals').insert({
            'owner_id': uid,
            'family_id': familyId,
            'member_id': newMemberId,
            'goal_name': 'Wealth Building for Retirement',
            'target_amount': 10000000,
            'target_date': targetDate.toIso8601String().substring(0, 10),
          });
        } catch (_) {
          // Non-fatal — member is created; user can add goal manually.
        }
      }

      // If Self, sync display_name → profiles.full_name
      if (_relationship == 'Self') {
        await supabase
            .from('profiles')
            .update({'full_name': _nameCtrl.text.trim()}).eq('id', uid);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: context.palette.loss),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.member?.relationship == 'Self') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cannot remove Self member'),
            backgroundColor: context.palette.loss),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content:
            Text('Remove "${widget.member!.displayName}" from family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: TextStyle(color: context.palette.loss)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('family_members')
          .delete()
          .eq('id', widget.member!.id);

      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: context.palette.loss),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

// ─── Entry Card (Risk Profiling / Goals) ─────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: context.palette.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

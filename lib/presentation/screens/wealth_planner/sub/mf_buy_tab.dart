import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/fund_model.dart';
import '../../../../data/models/pending_order_model.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/pending_orders_provider.dart';
import '../../../providers/selected_member_provider.dart';
import '../../../router/route_names.dart';
import '../../../widgets/common/fund_search_dropdown.dart';

const _kKindPref = 'buy_tab_kind';

class MfBuyTab extends ConsumerStatefulWidget {
  const MfBuyTab({super.key});

  @override
  ConsumerState<MfBuyTab> createState() => _MfBuyTabState();
}

class _MfBuyTabState extends ConsumerState<MfBuyTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  OrderKind _kind = OrderKind.lumpsum;
  FundModel? _selectedFund;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    try {
      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      final raw = box.get(_kKindPref);
      if (raw is String) {
        if (raw == OrderKind.sip.dbValue) {
          _kind = OrderKind.sip;
        } else if (raw == OrderKind.lumpsum.dbValue) {
          _kind = OrderKind.lumpsum;
        }
      }
    } catch (_) {
      // box not open in some test contexts
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setKind(OrderKind k) {
    setState(() => _kind = k);
    try {
      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      box.put(_kKindPref, k.dbValue);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fund')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final memberId = ref.read(selectedMemberProvider);
      final members = await ref.read(familyMembersProvider.future);
      String? familyId;
      if (memberId != null) {
        familyId = members
            .cast<FamilyMemberModel?>()
            .firstWhere((m) => m?.id == memberId, orElse: () => null)
            ?.familyId;
      }
      familyId ??= members.isNotEmpty ? members.first.familyId : null;

      final amount = double.parse(_amountCtrl.text.trim());
      final dateIso = _date.toUtc().toIso8601String();

      await ref.read(pendingOrdersMutatorProvider.notifier).add(
            fundName: _selectedFund!.fundName,
            kind: _kind,
            memberId: memberId,
            familyId: familyId,
            amfiCode: _selectedFund!.amfiCode,
            amount: amount,
            status: OrderStatus.placed,
            source: OrderSource.manual,
            notes: _notesCtrl.text.trim().isEmpty
                ? 'date=$dateIso'
                : '${_notesCtrl.text.trim()} | date=$dateIso',
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order recorded — see Order Status')),
      );
      setState(() {
        _selectedFund = null;
        _amountCtrl.clear();
        _notesCtrl.clear();
        _date = DateTime.now();
      });
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top strip ───────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to buy?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find funds that match your allocation gaps.',
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(Routes.marketIntel),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Open Smart Screener'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Manual order form ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.bgDivider),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Record a manual order',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Log an order you already placed with your broker.',
                  style: TextStyle(fontSize: 11, color: palette.textTertiary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _KindToggle(
                      label: 'Lumpsum',
                      selected: _kind == OrderKind.lumpsum,
                      onTap: () => _setKind(OrderKind.lumpsum),
                    ),
                    const SizedBox(width: 8),
                    _KindToggle(
                      label: 'SIP',
                      selected: _kind == OrderKind.sip,
                      onTap: () => _setKind(OrderKind.sip),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FundSearchDropdown(
                  initialFund: _selectedFund,
                  onSelected: (f) => setState(() => _selectedFund = f),
                ),
                if (_selectedFund != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Selected: ${_selectedFund!.fundName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final d = double.tryParse(v.trim());
                    if (d == null || d <= 0) return 'Enter a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Order date',
                      suffixIcon: Icon(Icons.calendar_today, size: 16),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_date),
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : context.palette.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primary : context.palette.bgDivider,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

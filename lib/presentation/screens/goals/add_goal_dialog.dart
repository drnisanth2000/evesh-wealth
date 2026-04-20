import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/family_model.dart';
import '../../../data/models/goal_model.dart';
import '../../providers/goal_provider.dart';

const _goalNameOptions = [
  'Wealth Building for Retirement',
  'Retirement',
  "Child's Education",
  "Child's Marriage",
  'Wealth Building',
  'Home Purchase',
  'Income Generation',
  'Capital Preservation',
  'Emergency Fund',
  'Vacation',
  'Vehicle Purchase',
  'Other',
];

class AddGoalDialog extends ConsumerStatefulWidget {
  const AddGoalDialog({
    super.key,
    required this.members,
    this.preselectedMemberId,
    this.preselectAll = false,
    this.existing,
  });

  /// All family members (for the member picker). Empty if editing — picker
  /// is hidden in edit mode.
  final List<FamilyMemberModel> members;

  /// Pre-selected member id (null = ALL/family-level).
  final String? preselectedMemberId;

  /// True if "ALL" tab is currently active.
  final bool preselectAll;

  /// If non-null, dialog is in edit mode for this goal.
  final GoalModel? existing;

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _memberId;
  bool _isAll = false;
  String _goalNameDropdown = 'Wealth Building for Retirement';
  final _customNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _memberId = existing.memberId;
      _isAll = existing.memberId == null;
      if (_goalNameOptions.contains(existing.goalName)) {
        _goalNameDropdown = existing.goalName;
      } else {
        _goalNameDropdown = 'Other';
        _customNameCtrl.text = existing.goalName;
      }
      _amountCtrl.text = existing.targetAmount.toStringAsFixed(0);
      _targetDate = existing.targetDateTime;
    } else {
      _isAll = widget.preselectAll;
      _memberId = widget.preselectedMemberId;
      _targetDate =
          DateTime.now().add(const Duration(days: 365 * 5)); // default 5 yrs
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Goal' : 'Add Goal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEdit) ...[
                _buildMemberPicker(),
                const SizedBox(height: 14),
              ],
              DropdownButtonFormField<String>(
                initialValue: _goalNameDropdown,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(),
                ),
                items: _goalNameOptions
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _goalNameDropdown = v);
                },
              ),
              if (_goalNameDropdown == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Custom Goal Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_goalNameDropdown == 'Other' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Enter a goal name';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Target Amount (Rs)',
                  prefixText: 'Rs ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Target Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _targetDate == null
                        ? 'Select date'
                        : '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Widget _buildMemberPicker() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: '__ALL__',
        child: Text('ALL (Family)'),
      ),
      ...widget.members.map(
        (m) => DropdownMenuItem<String?>(
          value: m.id,
          child: Text(m.displayName),
        ),
      ),
    ];
    final current = _isAll ? '__ALL__' : _memberId;
    return DropdownButtonFormField<String?>(
      initialValue: current,
      decoration: const InputDecoration(
        labelText: 'For',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (v) => setState(() {
        if (v == '__ALL__') {
          _isAll = true;
          _memberId = null;
        } else {
          _isAll = false;
          _memberId = v;
        }
      }),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 60)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a target date')),
      );
      return;
    }
    setState(() => _saving = true);

    final goalName = _goalNameDropdown == 'Other'
        ? _customNameCtrl.text.trim()
        : _goalNameDropdown;
    final amount = double.parse(_amountCtrl.text);

    try {
      if (widget.existing != null) {
        await ref.read(goalMutatorProvider.notifier).updateGoal(
              goalId: widget.existing!.id,
              goalName: goalName,
              targetAmount: amount,
              targetDate: _targetDate!,
            );
      } else {
        await ref.read(goalMutatorProvider.notifier).addGoal(
              memberId: _isAll ? null : _memberId,
              goalName: goalName,
              targetAmount: amount,
              targetDate: _targetDate!,
            );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../../data/models/watchlist_rule_model.dart';
import '../../../domain/models/screener_models.dart';
import '../../providers/screener_provider.dart';
import '../../providers/watchlist_provider.dart';

// ── Asset class options ───────────────────────────────────────────────────────

const _assetClasses = [
  (key: 'coreEquity', label: 'Core Equity'),
  (key: 'satelliteEquity', label: 'Satellite Equity'),
  (key: 'hybrid', label: 'Hybrid'),
  (key: 'debt', label: 'Debt'),
  (key: 'liquid', label: 'Liquid'),
  (key: 'gold', label: 'Gold'),
  (key: 'alternatives', label: 'Alternatives'),
];

// ── Rule type options ─────────────────────────────────────────────────────────

const _ruleTypes = [
  (value: 'stop_loss', label: 'Stop-Loss'),
  (value: 'gain_harvest', label: 'Gain Harvest'),
  (value: 'price_target', label: 'Price Target'),
  (value: 'allocation_drift', label: 'Allocation Drift'),
];

class AddRuleScreen extends ConsumerStatefulWidget {
  const AddRuleScreen({
    super.key,
    this.initialAmfiCode,
    this.initialFundName,
    this.editRule,
  });

  final int? initialAmfiCode;
  final String? initialFundName;
  final WatchlistRuleModel? editRule;

  @override
  ConsumerState<AddRuleScreen> createState() => _AddRuleScreenState();
}

class _AddRuleScreenState extends ConsumerState<AddRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _noteController = TextEditingController();

  // Section 1 — rule type
  String _ruleType = 'stop_loss';

  // Section 2 — fund selection
  int? _selectedAmfiCode;
  String? _selectedFundName;
  String _searchQuery = '';
  Timer? _debounce;

  // Section 2 — allocation drift asset class
  String? _selectedAssetClassKey;

  // Section 3 — threshold
  String _thresholdType = 'nav';
  // direction is auto-set from rule type

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFromEdit();
  }

  void _initFromEdit() {
    final edit = widget.editRule;
    if (edit != null) {
      _ruleType = edit.ruleType;
      _selectedAmfiCode = edit.amfiCode;
      _selectedFundName = edit.fundName;
      _selectedAssetClassKey = edit.assetClassKey;
      _thresholdType = edit.thresholdType;
      _thresholdController.text = edit.thresholdValue.toString();
      _noteController.text = edit.note ?? '';
    } else {
      // Pre-select fund if provided
      if (widget.initialAmfiCode != null) {
        _selectedAmfiCode = widget.initialAmfiCode;
        _selectedFundName = widget.initialFundName;
      }
      // Set default threshold type based on default rule type
      _thresholdType = _defaultThresholdType(_ruleType);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _thresholdController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _defaultThresholdType(String ruleType) {
    if (ruleType == 'price_target') return 'nav';
    if (ruleType == 'allocation_drift') return 'percentage';
    return 'nav';
  }

  String _directionFor(String ruleType) {
    if (ruleType == 'stop_loss') return 'below';
    return 'above';
  }

  bool _showFundSearch() => _ruleType != 'allocation_drift';

  bool _showThresholdSegmented() =>
      _ruleType != 'price_target' && _ruleType != 'allocation_drift';

  String _thresholdPrefix() {
    if (_thresholdType == 'percentage') return '%';
    return '₹';
  }

  // ── Rule type selection ───────────────────────────────────────────────────

  void _onRuleTypeChanged(String newType) {
    setState(() {
      _ruleType = newType;
      // Reset threshold type to appropriate default
      _thresholdType = _defaultThresholdType(newType);
      // Clear fund or asset class selection when switching modes
      if (newType == 'allocation_drift') {
        _selectedAmfiCode = null;
        _selectedFundName = null;
        _searchQuery = '';
        _searchController.clear();
      } else {
        _selectedAssetClassKey = null;
      }
    });
  }

  // ── Fund search ───────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value);
      }
    });
  }

  void _selectFund(FundModel fund) {
    setState(() {
      _selectedAmfiCode = fund.amfiCode;
      _selectedFundName = fund.fundName;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _deselectFund() {
    setState(() {
      _selectedAmfiCode = null;
      _selectedFundName = null;
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation
    if (_showFundSearch() && _selectedAmfiCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a fund.')),
      );
      return;
    }
    if (_ruleType == 'allocation_drift' && _selectedAssetClassKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an asset class.')),
      );
      return;
    }

    final thresholdValue = double.tryParse(_thresholdController.text.trim());
    if (thresholdValue == null || thresholdValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid threshold value.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(watchlistNotifierProvider.notifier);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      final direction = _directionFor(_ruleType);
      final thresholdType =
          _ruleType == 'price_target' || _ruleType == 'allocation_drift'
              ? _defaultThresholdType(_ruleType)
              : _thresholdType;

      if (widget.editRule != null) {
        await notifier.updateRule(widget.editRule!.id, {
          'rule_type': _ruleType,
          'threshold_type': thresholdType,
          'threshold_value': thresholdValue,
          'direction': direction,
          if (_selectedAmfiCode != null) 'amfi_code': _selectedAmfiCode,
          if (_selectedFundName != null) 'fund_name': _selectedFundName,
          if (_selectedAssetClassKey != null)
            'asset_class_key': _selectedAssetClassKey,
          if (note != null) 'note': note else 'note': null,
        });
      } else {
        await notifier.addRule(
          amfiCode: _showFundSearch() ? _selectedAmfiCode : null,
          fundName: _showFundSearch() ? _selectedFundName : null,
          ruleType: _ruleType,
          thresholdType: thresholdType,
          thresholdValue: thresholdValue,
          direction: direction,
          assetClassKey:
              _ruleType == 'allocation_drift' ? _selectedAssetClassKey : null,
          note: note,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editRule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Rule' : 'Add Rule'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel(label: 'Rule Type'),
            const SizedBox(height: 12),
            _buildRuleTypeChips(context),
            const SizedBox(height: 24),
            if (_showFundSearch()) ...[
              _SectionLabel(label: 'Fund Selection'),
              const SizedBox(height: 12),
              _buildFundSection(context),
              const SizedBox(height: 24),
            ] else ...[
              _SectionLabel(label: 'Asset Class'),
              const SizedBox(height: 12),
              _buildAssetClassDropdown(context),
              const SizedBox(height: 24),
            ],
            _SectionLabel(label: 'Threshold'),
            const SizedBox(height: 12),
            _buildThresholdSection(),
            const SizedBox(height: 24),
            _SectionLabel(label: 'Note (optional)'),
            const SizedBox(height: 12),
            _buildNoteField(context),
            const SizedBox(height: 32),
            _buildSaveButton(isEdit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Rule type chips ────────────────────────────────────────────

  Widget _buildRuleTypeChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ruleTypes.map((rt) {
        final selected = _ruleType == rt.value;
        return ChoiceChip(
          label: Text(rt.label),
          selected: selected,
          onSelected: (_) => _onRuleTypeChanged(rt.value),
          selectedColor: AppColors.primary,
          backgroundColor: context.palette.bgSurface,
          labelStyle: TextStyle(
            color: selected ? Colors.white : context.palette.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : context.palette.bgDivider,
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  // ── Section 2: Fund search ────────────────────────────────────────────────

  Widget _buildFundSection(BuildContext context) {
    // Show selected fund chip
    if (_selectedAmfiCode != null && _selectedFundName != null) {
      return _SelectedFundChip(
        fundName: _selectedFundName!,
        onRemove: _deselectFund,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search fund by name...',
            prefixIcon: Icon(Icons.search, color: context.palette.textTertiary),
            filled: true,
            fillColor: context.palette.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.palette.bgDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: context.palette.bgDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary),
            ),
            hintStyle:
                TextStyle(color: context.palette.textTertiary),
          ),
          style: TextStyle(color: context.palette.textPrimary),
          keyboardType: TextInputType.text,
        ),
        if (_searchQuery.length >= 2) ...[
          const SizedBox(height: 8),
          _FundSearchResults(
            query: _searchQuery,
            onSelect: _selectFund,
          ),
        ],
      ],
    );
  }

  // ── Section 2: Asset class dropdown ──────────────────────────────────────

  Widget _buildAssetClassDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedAssetClassKey,
      hint: Text(
        'Select asset class',
        style: TextStyle(color: context.palette.textTertiary),
      ),
      dropdownColor: context.palette.bgCard,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.palette.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      style: TextStyle(color: context.palette.textPrimary),
      items: _assetClasses
          .map(
            (ac) => DropdownMenuItem<String>(
              value: ac.key,
              child: Text(ac.label),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedAssetClassKey = val),
      validator: (val) {
        if (_ruleType == 'allocation_drift' && val == null) {
          return 'Please select an asset class';
        }
        return null;
      },
    );
  }

  // ── Section 3: Threshold ──────────────────────────────────────────────────

  Widget _buildThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showThresholdSegmented()) ...[
          _buildThresholdTypeSegmented(context),
          const SizedBox(height: 16),
        ],
        _buildThresholdValueField(context),
      ],
    );
  }

  Widget _buildThresholdTypeSegmented(BuildContext context) {
    final segments = [
      const ButtonSegment<String>(value: 'nav', label: Text('NAV (₹)')),
      const ButtonSegment<String>(value: 'amount', label: Text('Amount (₹)')),
      const ButtonSegment<String>(value: 'percentage', label: Text('% Change')),
    ];

    return SegmentedButton<String>(
      segments: segments,
      selected: {_thresholdType},
      onSelectionChanged: (val) {
        setState(() => _thresholdType = val.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return context.palette.bgSurface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return context.palette.textSecondary;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: context.palette.bgDivider),
        ),
      ),
    );
  }

  Widget _buildThresholdValueField(BuildContext context) {
    final effectiveType =
        (_ruleType == 'price_target' || _ruleType == 'allocation_drift')
            ? _defaultThresholdType(_ruleType)
            : _thresholdType;
    final prefix = effectiveType == 'percentage' ? '%' : '₹';
    final label = effectiveType == 'percentage'
        ? 'Percentage threshold'
        : effectiveType == 'nav'
            ? 'NAV target (₹)'
            : 'Amount threshold (₹)';

    return TextFormField(
      controller: _thresholdController,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.palette.textSecondary),
        prefixText: '$prefix ',
        prefixStyle:
            TextStyle(color: context.palette.textPrimary),
        filled: true,
        fillColor: context.palette.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.loss),
        ),
      ),
      style: TextStyle(color: context.palette.textPrimary),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Please enter a threshold value';
        }
        final parsed = double.tryParse(val.trim());
        if (parsed == null || parsed <= 0) {
          return 'Enter a valid value greater than 0';
        }
        return null;
      },
    );
  }

  // ── Note field ────────────────────────────────────────────────────────────

  Widget _buildNoteField(BuildContext context) {
    return TextFormField(
      controller: _noteController,
      maxLines: 1,
      decoration: InputDecoration(
        hintText: 'Add a note...',
        hintStyle: TextStyle(color: context.palette.textTertiary),
        filled: true,
        fillColor: context.palette.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.palette.bgDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      style: TextStyle(color: context.palette.textPrimary),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────

  Widget _buildSaveButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withValues(alpha: 0.5),
          padding:
              const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                isEdit ? 'Update Rule' : 'Save Rule',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SelectedFundChip extends StatelessWidget {
  const _SelectedFundChip({
    required this.fundName,
    required this.onRemove,
  });

  final String fundName;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fundName,
              style: TextStyle(
                color: context.palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                color: context.palette.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FundSearchResults extends ConsumerWidget {
  const _FundSearchResults({
    required this.query,
    required this.onSelect,
  });

  final String query;
  final ValueChanged<FundModel> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(
      screenerResultsProvider(ScreenerFilters(searchQuery: query)),
    );

    return resultsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppColors.loss, fontSize: 12),
        ),
      ),
      data: (funds) {
        if (funds.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No funds found',
              style: TextStyle(color: context.palette.textTertiary, fontSize: 13),
            ),
          );
        }

        final limited = funds.take(5).toList();
        return Container(
          decoration: BoxDecoration(
            color: context.palette.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.palette.bgDivider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: limited.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: context.palette.bgDivider,
            ),
            itemBuilder: (context, index) {
              final fund = limited[index].fund;
              final nav = fund.latestNav;
              return ListTile(
                dense: true,
                title: Text(
                  fund.fundName,
                  style: TextStyle(
                    color: context.palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  fund.category ?? '',
                  style: TextStyle(
                    color: context.palette.textTertiary,
                    fontSize: 11,
                  ),
                ),
                trailing: nav != null
                    ? Text(
                        '₹${nav.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: context.palette.textSecondary,
                          fontSize: 12,
                        ),
                      )
                    : null,
                onTap: () => onSelect(fund),
              );
            },
          ),
        );
      },
    );
  }
}

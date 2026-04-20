import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/family_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/fund_search_dropdown.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.editTransaction});

  /// If non-null, the screen operates in edit mode with fields pre-filled.
  final TransactionModel? editTransaction;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Asset type
  AssetType _assetType = AssetType.mf;

  // MF-specific
  FundModel? _selectedFund;

  // Other assets
  final _assetNameCtrl = TextEditingController();
  final _isinCtrl = TextEditingController();

  // Common fields
  TransactionType _txType = TransactionType.buy;
  DateTime _txDate = DateTime.now();
  final _amountCtrl = TextEditingController();
  final _unitsCtrl = TextEditingController();
  final _navCtrl = TextEditingController();
  final _folioCtrl = TextEditingController();
  final _brokerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _stoplossCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();

  String? _memberId;
  bool _showAdvanced = false;

  bool get _isEditMode => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.editTransaction;
    if (tx == null) return;

    // Pre-fill from existing transaction
    _assetType = AssetType.values.firstWhere(
      (a) => a.dbValue == tx.assetType,
      orElse: () => AssetType.other,
    );
    _txType = TransactionType.fromString(tx.txType);
    _txDate = DateTime.tryParse(tx.txDate) ?? DateTime.now();
    _memberId = tx.memberId;
    _amountCtrl.text = tx.amount.toStringAsFixed(2);
    if (tx.units != null) _unitsCtrl.text = tx.units!.toStringAsFixed(4);
    if (tx.navAtTx != null) _navCtrl.text = tx.navAtTx!.toStringAsFixed(4);
    if (tx.folioNumber != null) _folioCtrl.text = tx.folioNumber!;
    if (tx.broker != null) _brokerCtrl.text = tx.broker!;
    if (tx.notes != null) _notesCtrl.text = tx.notes!;
    if (tx.targetAmount != null) _targetCtrl.text = tx.targetAmount!.toStringAsFixed(2);
    if (tx.stoplossAmount != null) _stoplossCtrl.text = tx.stoplossAmount!.toStringAsFixed(2);
    if (tx.currentValue != null) _currentValueCtrl.text = tx.currentValue!.toStringAsFixed(2);

    // Non-MF asset name
    if (_assetType != AssetType.mf) {
      _assetNameCtrl.text = tx.assetName ?? tx.fundMaster?.fundName ?? '';
    }
    if (tx.isin != null) _isinCtrl.text = tx.isin!;

    // Show advanced if any advanced fields have data
    if (tx.folioNumber != null || tx.broker != null || tx.notes != null ||
        tx.targetAmount != null || tx.stoplossAmount != null) {
      _showAdvanced = true;
    }
  }

  static const _mfTxTypes = [
    TransactionType.buy,
    TransactionType.sip,
    TransactionType.sell,
    TransactionType.swp,
    TransactionType.switchIn,
    TransactionType.switchOut,
    TransactionType.stpIn,
    TransactionType.stpOut,
    TransactionType.idcw,
    TransactionType.bonus,
  ];

  static const _stockTxTypes = [
    TransactionType.stxBuy,
    TransactionType.stxSell,
  ];

  static const _otherTxTypes = [
    TransactionType.buy,
    TransactionType.sell,
  ];

  static const _incomeAssetTxTypes = [
    TransactionType.buy,
    TransactionType.sell,
    TransactionType.interest,
    TransactionType.maturity,
  ];

  static const _dividendAssetTxTypes = [
    TransactionType.buy,
    TransactionType.sell,
    TransactionType.dividend,
  ];

  List<TransactionType> get _availableTxTypes {
    switch (_assetType) {
      case AssetType.mf:
        return _mfTxTypes;
      case AssetType.stock:
        return _stockTxTypes;
      case AssetType.sgb:
      case AssetType.fd:
      case AssetType.ppf:
        return _incomeAssetTxTypes;
      case AssetType.reit:
      case AssetType.invIt:
      case AssetType.aif:
      case AssetType.sif:
        return _dividendAssetTxTypes;
      case AssetType.nps:
        return [TransactionType.buy, TransactionType.sell, TransactionType.maturity];
      default:
        return _otherTxTypes;
    }
  }

  @override
  void dispose() {
    _assetNameCtrl.dispose();
    _isinCtrl.dispose();
    _amountCtrl.dispose();
    _unitsCtrl.dispose();
    _navCtrl.dispose();
    _folioCtrl.dispose();
    _brokerCtrl.dispose();
    _notesCtrl.dispose();
    _targetCtrl.dispose();
    _stoplossCtrl.dispose();
    _currentValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _txDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _txDate = d);
  }

  void _onAssetTypeChanged(AssetType? type) {
    if (type == null) return;
    setState(() {
      _assetType = type;
      _selectedFund = null;
      _txType = _availableTxTypes.first;
    });
  }

  void _onUnitsOrNavChanged() {
    final units = double.tryParse(_unitsCtrl.text);
    final nav = double.tryParse(_navCtrl.text);
    if (units != null && nav != null && units > 0 && nav > 0) {
      final amount = units * nav;
      _amountCtrl.text = amount.toStringAsFixed(2);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assetType == AssetType.mf && _selectedFund == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a fund')));
      return;
    }

    final membersAsync = ref.read(familyMembersProvider);
    final members = membersAsync.valueOrNull ?? [];
    String? familyId;
    if (members.isNotEmpty) {
      final familyAsync = ref.read(familyProvider);
      familyId = familyAsync.valueOrNull?.id;
    }

    final input = TransactionInput(
      familyId: familyId,
      memberId: _memberId,
      amfiCode: _selectedFund?.amfiCode,
      isin: _isinCtrl.text.trim().isEmpty
          ? _selectedFund?.isinGrowth
          : _isinCtrl.text.trim(),
      assetName: _assetType == AssetType.mf
          ? _selectedFund?.fundName
          : _assetNameCtrl.text.trim(),
      assetType: _assetType,
      txDate: DateFormat('yyyy-MM-dd').format(_txDate),
      txType: _txType,
      units: double.tryParse(_unitsCtrl.text),
      navAtTx: double.tryParse(_navCtrl.text),
      amount: double.parse(_amountCtrl.text),
      folioNumber:
          _folioCtrl.text.trim().isEmpty ? null : _folioCtrl.text.trim(),
      broker: _brokerCtrl.text.trim().isEmpty ? null : _brokerCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      targetAmount: double.tryParse(_targetCtrl.text),
      stoplossAmount: double.tryParse(_stoplossCtrl.text),
      currentValue: double.tryParse(_currentValueCtrl.text),
    );

    final notifier = ref.read(transactionNotifierProvider.notifier);
    final String? error;
    if (_isEditMode) {
      error = await notifier.updateTransaction(widget.editTransaction!.id, input);
    } else {
      error = await notifier.addTransaction(input);
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.loss));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Transaction updated' : 'Transaction added successfully'),
          backgroundColor: AppColors.gain,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(familyMembersProvider);
    final members = membersAsync.valueOrNull ?? [];
    final isSaving =
        ref.watch(transactionNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Asset type selector ───────────────────────────────────────
            _SectionLabel('Asset Type'),
            _AssetTypeSelector(
              selected: _assetType,
              onChanged: _onAssetTypeChanged,
            ),
            const SizedBox(height: 16),

            // ── Member selector ───────────────────────────────────────────
            if (members.isNotEmpty) ...[
              _SectionLabel('Member'),
              DropdownButtonFormField<String?>(
                value: _memberId,
                decoration: const InputDecoration(hintText: 'Select member'),
                items: members.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.displayName),
                    )).toList(),
                validator: (v) =>
                    v == null ? 'Please select a member' : null,
                onChanged: (v) => setState(() => _memberId = v),
              ),
              const SizedBox(height: 16),
            ],

            // ── Fund / asset search ───────────────────────────────────────
            if (_assetType == AssetType.mf) ...[
              _SectionLabel('Fund'),
              FundSearchDropdown(
                initialFund: _selectedFund,
                onSelected: (fund) {
                  setState(() {
                    _selectedFund = fund;
                    if (fund.latestNav != null) {
                      _navCtrl.text = fund.latestNav!.toStringAsFixed(4);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              _SectionLabel('Asset Name'),
              TextFormField(
                controller: _assetNameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. HDFC Bank'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (_assetType == AssetType.stock) ...[
                _SectionLabel('ISIN / Symbol (optional)'),
                TextFormField(
                  controller: _isinCtrl,
                  decoration:
                      const InputDecoration(hintText: 'e.g. INE040A01034'),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // ── Transaction type ──────────────────────────────────────────
            _SectionLabel('Transaction Type'),
            DropdownButtonFormField<TransactionType>(
              value: _txType,
              decoration: const InputDecoration(),
              items: _availableTxTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _txType = v);
              },
            ),
            const SizedBox(height: 16),

            // ── Date ──────────────────────────────────────────────────────
            _SectionLabel('Transaction Date'),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: DateFormat('dd MMM yyyy').format(_txDate),
                  ),
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Amount / Units / NAV ──────────────────────────────────────
            if (_assetType == AssetType.mf || _assetType == AssetType.stock) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Units'),
                        TextFormField(
                          controller: _unitsCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(hintText: '0.000'),
                          onChanged: (_) => _onUnitsOrNavChanged(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('NAV / Price (₹)'),
                        TextFormField(
                          controller: _navCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(hintText: '0.00'),
                          onChanged: (_) => _onUnitsOrNavChanged(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _SectionLabel('Amount (₹)'),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0.00',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Current Value (for manual asset types) ──────────────────
            if (_assetType.isManualValuation) ...[
              _SectionLabel('Current Value (₹)'),
              TextFormField(
                controller: _currentValueCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  hintText: 'Today\'s value of this holding',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the current market value to track returns',
                style: TextStyle(fontSize: 11, color: context.palette.textTertiary),
              ),
              const SizedBox(height: 16),
            ],

            // ── Advanced fields toggle ────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Text(
                    _showAdvanced ? 'Hide advanced fields' : 'Show advanced fields',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.primary),
                  ),
                  Icon(
                    _showAdvanced
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              _SectionLabel('Folio Number'),
              TextFormField(
                controller: _folioCtrl,
                decoration: const InputDecoration(hintText: 'e.g. 12345678/90'),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Broker / AMC'),
              TextFormField(
                controller: _brokerCtrl,
                decoration: const InputDecoration(
                    hintText: 'e.g. Zerodha, MF Central'),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Price Target (₹)'),
              TextFormField(
                controller: _targetCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Alert above this NAV'),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Stop-Loss (₹)'),
              TextFormField(
                controller: _stoplossCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Alert below this NAV'),
              ),
              const SizedBox(height: 12),
              _SectionLabel('Notes'),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Optional notes'),
              ),
            ],

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditMode ? 'Update Transaction' : 'Save Transaction',
                      style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: context.palette.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AssetTypeSelector extends StatelessWidget {
  const _AssetTypeSelector({required this.selected, required this.onChanged});
  final AssetType selected;
  final void Function(AssetType?) onChanged;

  static const _types = [
    (AssetType.mf, Icons.account_balance, 'Mutual Fund'),
    (AssetType.stock, Icons.show_chart, 'Stock'),
    (AssetType.pms, Icons.business_center, 'PMS'),
    (AssetType.gold, Icons.monetization_on, 'Gold'),
    (AssetType.realEstate, Icons.home, 'Real Estate'),
    (AssetType.sgb, Icons.savings_outlined, 'SGB'),
    (AssetType.reit, Icons.business_outlined, 'REIT'),
    (AssetType.invIt, Icons.factory_outlined, 'InvIT'),
    (AssetType.fd, Icons.lock_clock_outlined, 'FD'),
    (AssetType.ppf, Icons.shield_outlined, 'PPF'),
    (AssetType.nps, Icons.elderly_outlined, 'NPS'),
    (AssetType.aif, Icons.trending_up_outlined, 'AIF'),
    (AssetType.sif, Icons.pie_chart_outline, 'SIF'),
    (AssetType.other, Icons.more_horiz, 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((t) {
        final isSelected = selected == t.$1;
        return GestureDetector(
          onTap: () => onChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.15)
                  : context.palette.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : context.palette.bgDivider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t.$2,
                  size: 14,
                  color: isSelected ? AppColors.primary : context.palette.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  t.$3,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : context.palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

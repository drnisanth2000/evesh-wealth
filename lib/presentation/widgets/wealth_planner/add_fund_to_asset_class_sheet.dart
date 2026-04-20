import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/asset_class_resolver.dart';
import '../../../core/constants/asset_classes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../providers/asset_class_override_provider.dart';
import '../../providers/simulation_provider.dart';
import '../common/fund_search_dropdown.dart';

/// Add-Fund bottom sheet — Step 1 of the "confirm-then-write" deployment
/// flow. The user picks an AMFI fund + asset class + lumpsum amount. On
/// confirm, we:
///   1. Write a placeholder target into `simState.fundAmounts` (sum of
///      lumpsum + sip×12 — rough shorthand so Rebalance can already
///      recommend moves).
///   2. If the resolver would not classify the fund under the chosen class,
///      write an `asset_class_override` so the Fund tab displays it under
///      the expected card.
///   3. Flag the fund in `simState.pendingDeployments` so each sub-card
///      badges it and surfaces an "Execute deployment" CTA. Actual
///      `pending_orders` insertion happens in Step 2 from inside the card.
class AddFundToAssetClassSheet extends ConsumerStatefulWidget {
  const AddFundToAssetClassSheet({
    super.key,
    required this.memberId,
    this.initialAssetClass,
  });

  final String? memberId;
  final AssetClass? initialAssetClass;

  static Future<void> show({
    required BuildContext context,
    required String? memberId,
    AssetClass? initialAssetClass,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFundToAssetClassSheet(
        memberId: memberId,
        initialAssetClass: initialAssetClass,
      ),
    );
  }

  @override
  ConsumerState<AddFundToAssetClassSheet> createState() =>
      _AddFundToAssetClassSheetState();
}

class _AddFundToAssetClassSheetState
    extends ConsumerState<AddFundToAssetClassSheet> {
  late AssetClass _assetClass;
  FundModel? _fund;
  final _lumpsumCtrl = TextEditingController();
  final _sipCtrl = TextEditingController();
  final _rupeesFmt = NumberFormat('#,##,###', 'en_IN');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _assetClass = widget.initialAssetClass ?? AssetClass.coreEquity;
  }

  @override
  void dispose() {
    _lumpsumCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  double get _lumpsum =>
      double.tryParse(_lumpsumCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  double get _sip =>
      double.tryParse(_sipCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  double get _simAmount => _lumpsum + _sip * 12;

  Future<void> _save() async {
    final fund = _fund;
    if (fund == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a fund first')),
      );
      return;
    }
    if (_simAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a lumpsum or SIP amount')),
      );
      return;
    }

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final notifier =
          ref.read(simulationStateProvider(widget.memberId).notifier);
      notifier.setFundAmount(fund.amfiCode, _simAmount);
      notifier.markPendingDeployment(
        fund.amfiCode,
        fundName: fund.fundName,
        assetClassName: _assetClass.name,
      );

      // If the resolver wouldn't put this fund under the user's chosen
      // class, write an override so the grouping matches their intent.
      final resolved = resolveAssetClass(
        amfiCategoryId: fund.amfiCategoryId,
        assetClassLabel: null,
        category: fund.category,
      );
      if (resolved != _assetClass) {
        await ref
            .read(assetClassOverrideMutatorProvider.notifier)
            .setForFund(amfiCode: fund.amfiCode, assetClass: _assetClass);
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Added ${fund.fundName} — execute deployment from the card.',
        ),
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text('Add failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add fund',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Simulate first. Execute the deployment from the fund card once you\u2019re ready.',
              style: TextStyle(fontSize: 11, color: palette.textTertiary),
            ),
            const SizedBox(height: 14),
            Text(
              'Asset class',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cls in AssetClass.values)
                  ChoiceChip(
                    label: Text(
                      cls.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _assetClass == cls,
                    onSelected: (_) => setState(() => _assetClass = cls),
                    selectedColor: (AppColors
                            .assetClassColors[cls.displayName] ??
                        AppColors.primary)
                        .withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _assetClass == cls
                          ? palette.textPrimary
                          : palette.textSecondary,
                      fontWeight: _assetClass == cls
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Fund',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            FundSearchDropdown(
              onSelected: (f) => setState(() => _fund = f),
              initialFund: _fund,
              hintText: 'Search AMFI fund master...',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lumpsumCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Lumpsum (₹)',
                      prefixText: '₹',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      fillColor: palette.bgSurface,
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _sipCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'SIP (₹/mo)',
                      prefixText: '₹',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      fillColor: palette.bgSurface,
                      filled: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_simAmount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Simulated target: ₹${_rupeesFmt.format(_simAmount.round())} '
                        '(lumpsum + 12 × SIP).',
                        style: TextStyle(
                            fontSize: 11, color: palette.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

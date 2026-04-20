import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/other_asset_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/other_assets_provider.dart';

class OtherAssetsScreen extends ConsumerWidget {
  const OtherAssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final assetsAsync = ref.watch(otherAssetsProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: assetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (assets) {
          if (assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 56, color: context.palette.textTertiary),
                  const SizedBox(height: 12),
                  Text('No other assets yet',
                      style: TextStyle(
                          color: context.palette.textSecondary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Add SGBs, FDs, REITs, PMS, Real Estate...',
                      style: TextStyle(
                          fontSize: 12, color: context.palette.textTertiary)),
                ],
              ),
            );
          }

          final grouped = <String, List<OtherAssetModel>>{};
          for (final a in assets) {
            (grouped[a.assetType] ??= []).add(a);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final typeTotal = entry.value
                  .map((a) => a.effectiveValue)
                  .fold(0.0, (a, b) => a + b);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(entry.key,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.palette.textSecondary)),
                        const Spacer(),
                        Text(typeTotal.toINRCompact(),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  ...entry.value.map((a) => _AssetTile(asset: a)),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => const _AddOtherAssetSheet(),
    );
  }
}

class _AddOtherAssetSheet extends ConsumerStatefulWidget {
  const _AddOtherAssetSheet();

  @override
  ConsumerState<_AddOtherAssetSheet> createState() =>
      _AddOtherAssetSheetState();
}

class _AddOtherAssetSheetState extends ConsumerState<_AddOtherAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _maturityCtrl = TextEditingController();
  String _assetType = 'SGB';
  bool _saving = false;

  static final _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  @override
  void dispose() {
    _descCtrl.dispose();
    _costCtrl.dispose();
    _currentCtrl.dispose();
    _maturityCtrl.dispose();
    super.dispose();
  }

  String? _validateAmount(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final parsed = double.tryParse(v.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Must be >= 0';
    return null;
  }

  String? _validateMaturity(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!_dateRegex.hasMatch(v.trim())) return 'Use YYYY-MM-DD';
    return null;
  }

  double? _parseOptional(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final mutator = ref.read(otherAssetsMutatorProvider.notifier);
      final maturity = _maturityCtrl.text.trim();
      await mutator.add(
        assetType: _assetType,
        description: _descCtrl.text.trim(),
        costValue: _parseOptional(_costCtrl.text),
        currentValue: _parseOptional(_currentCtrl.text),
        maturityDate: maturity.isEmpty ? null : maturity,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Asset',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _assetType,
              decoration: const InputDecoration(labelText: 'Asset Type'),
              items: const [
                'SGB', 'REIT', 'InvIT', 'FD', 'PPF', 'NPS',
                'PMS', 'AIF', 'SIF', 'Gold', 'RealEstate', 'Other',
              ]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _assetType = v);
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Cost (₹)', prefixText: '₹ '),
                  validator: _validateAmount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _currentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Current Value (₹)', prefixText: '₹ '),
                  validator: _validateAmount,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maturityCtrl,
              decoration: const InputDecoration(
                  labelText: 'Maturity Date (YYYY-MM-DD)',
                  hintText: 'Optional'),
              validator: _validateMaturity,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.asset});
  final OtherAssetModel asset;

  @override
  Widget build(BuildContext context) {
    final cost = asset.costValue ?? 0;
    final current = asset.effectiveValue;
    final maturity = asset.maturityDate;
    final gain = current - cost;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(asset.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14)),
        subtitle: maturity != null
            ? Text('Matures: $maturity',
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary))
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(current.toINRCompact(),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text(
              '${gain >= 0 ? '+' : ''}${gain.toINRCompact()}',
              style: TextStyle(
                  fontSize: 11,
                  color: gain >= 0 ? AppColors.gain : AppColors.loss),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/bucket_mapping.dart';
import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../../data/models/portfolio_summary_model.dart';
import '../../providers/pending_moves_provider.dart';
import '../common/fund_search_dropdown.dart';

/// Unified From→To card used by both Reallocation and Deployment sections of
/// the Rebalance → Actions sub-tab.
///
/// - When [destinationOptions] has entries, the destination is a dropdown of
///   existing holdings in the target bucket (+ an "Add new fund…" tail).
/// - When [destinationOptions] is empty, the card embeds [FundSearchDropdown]
///   inline so the user can resolve a brand-new fund without leaving the flow.
///
/// Registers a [PendingMove] into [pendingMovesProvider] on mount and updates
/// it when the user changes destination/amount. Deregisters on dispose. This
/// drives the faint-text "Arriving" rows on the Buckets sub-tab.
class MoveCard extends ConsumerStatefulWidget {
  const MoveCard({
    super.key,
    required this.id,
    required this.kind,
    required this.fromBucket,
    required this.fromAmfi,
    required this.fromFundName,
    required this.toBucket,
    required this.initialToAmfi,
    required this.initialToFundName,
    required this.initialAmount,
    required this.destinationOptions,
    required this.onSave,
    required this.onDismiss,
    required this.onExecute,
    this.reason,
    this.busy = false,
    this.toBucketCurrentValue,
    this.concentrationLimitPct = 35,
  });

  final String id;
  final PendingMoveKind kind;
  final Bucket fromBucket;
  final int? fromAmfi;
  final String fromFundName;
  final Bucket toBucket;
  final int? initialToAmfi;
  final String? initialToFundName;
  final double initialAmount;
  final List<FundHoldingSummary> destinationOptions;
  final String? reason;
  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onDismiss;
  final void Function(int? toAmfi, String toFundName, double amount) onExecute;

  /// Current rupee value of the destination bucket (pre-move). Used to
  /// compute concentration warning. When null, warning is suppressed.
  final double? toBucketCurrentValue;

  /// Single-fund concentration threshold inside the destination bucket.
  /// If the picked destination would cross this % post-move, show a warning
  /// (advisory — user can still execute). Default 35 follows retail practice
  /// (no single fund > ~35% of its bucket).
  final double concentrationLimitPct;

  @override
  ConsumerState<MoveCard> createState() => _MoveCardState();
}

class _MoveCardState extends ConsumerState<MoveCard> {
  late int? _toAmfi = widget.initialToAmfi;
  late String _toName = widget.initialToFundName ?? '';
  late final TextEditingController _amountCtl =
      TextEditingController(text: widget.initialAmount.toStringAsFixed(0));
  bool _expanded = false;
  bool _registered = false;
  // Cached so we can deregister from dispose() — `ref` is invalidated by then.
  PendingMoves? _notifier;

  double get _amount =>
      double.tryParse(_amountCtl.text.trim()) ?? widget.initialAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _register());
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    if (_registered) {
      _notifier?.remove(widget.id);
    }
    super.dispose();
  }

  void _register() {
    if (!mounted) return;
    _notifier ??= ref.read(pendingMovesProvider.notifier);
    _notifier!.upsert(PendingMove(
      id: widget.id,
      fromAmfi: widget.fromAmfi,
      fromFundName: widget.fromFundName,
      fromBucket: widget.fromBucket,
      toAmfi: _toAmfi,
      toFundName: _toName,
      toBucket: widget.toBucket,
      amount: _amount,
      kind: widget.kind,
    ));
    _registered = true;
  }

  void _updatePending() {
    if (!_registered || _notifier == null) return;
    _notifier!.upsert(PendingMove(
      id: widget.id,
      fromAmfi: widget.fromAmfi,
      fromFundName: widget.fromFundName,
      fromBucket: widget.fromBucket,
      toAmfi: _toAmfi,
      toFundName: _toName,
      toBucket: widget.toBucket,
      amount: _amount,
      kind: widget.kind,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasExisting = widget.destinationOptions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.bgDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(palette),
          const SizedBox(height: 8),
          if (_expanded) ...[
            if (hasExisting)
              _existingDropdown(palette)
            else
              _inlineSearch(palette),
            const SizedBox(height: 8),
            _amountRow(palette),
            if (_concentrationWarning() != null) ...[
              const SizedBox(height: 6),
              _concentrationWarning()!,
            ],
            if (widget.reason != null) ...[
              const SizedBox(height: 6),
              Text(widget.reason!,
                  style: TextStyle(fontSize: 11, color: palette.textTertiary)),
            ],
            const SizedBox(height: 10),
            _actionRow(),
          ],
        ],
      ),
    );
  }

  Widget _header(AppPalette palette) {
    final color = widget.kind == PendingMoveKind.reallocation
        ? AppColors.info
        : AppColors.primary;
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move ${_amount.toINRCompact()}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _fromToLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: palette.textTertiary),
                ),
              ],
            ),
          ),
          _bucketPill(widget.fromBucket),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 12),
          ),
          _bucketPill(widget.toBucket),
          Icon(_expanded ? Icons.expand_less : Icons.chevron_right,
              size: 18, color: palette.textTertiary),
        ],
      ),
    );
  }

  String _fromToLine() {
    final to = _toName.isEmpty ? '(select fund)' : _toName;
    return '${widget.fromFundName} → $to';
  }

  Widget _bucketPill(Bucket b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: b.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        b.shortLabel,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: b.color),
      ),
    );
  }

  Widget _existingDropdown(AppPalette palette) {
    final items = widget.destinationOptions
        .where((h) => h.amfiCode != widget.fromAmfi)
        .toList()
      ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
    final valueInList = items.any((h) => h.amfiCode == _toAmfi);

    return Row(
      children: [
        Icon(Icons.south_east, size: 14, color: palette.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: valueInList ? _toAmfi : null,
              hint: Text(_toName.isEmpty ? 'Choose destination fund' : _toName,
                  style:
                      TextStyle(fontSize: 13, color: palette.textSecondary)),
              items: [
                for (final h in items)
                  DropdownMenuItem<int>(
                    value: h.amfiCode,
                    child: Text(h.fundName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: palette.textPrimary)),
                  ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Row(children: [
                    Icon(Icons.add, size: 14, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text('Add new fund…',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ]),
                ),
              ],
              onChanged: (v) async {
                if (v == null) return;
                if (v == -1) {
                  await _openInlineSearch();
                  return;
                }
                final picked = items.firstWhere((h) => h.amfiCode == v);
                setState(() {
                  _toAmfi = picked.amfiCode;
                  _toName = picked.fundName;
                });
                _updatePending();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineSearch(AppPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 12, color: palette.textTertiary),
            const SizedBox(width: 6),
            Text(
              'No fund in ${widget.toBucket.displayName} yet — pick one:',
              style: TextStyle(fontSize: 11, color: palette.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FundSearchDropdown(
          initialFund: _toName.isEmpty
              ? null
              : FundModel(
                  amfiCode: _toAmfi ?? 0,
                  fundName: _toName,
                ),
          onSelected: (fund) {
            setState(() {
              _toAmfi = fund.amfiCode;
              _toName = fund.fundName;
            });
            _updatePending();
          },
        ),
      ],
    );
  }

  Future<void> _openInlineSearch() async {
    final picked = await showModalBottomSheet<FundModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: FundSearchDropdown(
            onSelected: (fund) => Navigator.pop(ctx, fund),
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _toAmfi = picked.amfiCode;
        _toName = picked.fundName;
      });
      _updatePending();
    }
  }

  Widget _amountRow(AppPalette palette) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: TextField(
            controller: _amountCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              isDense: true,
              prefixText: '₹ ',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: palette.bgDivider),
              ),
            ),
            style: TextStyle(fontSize: 13, color: palette.textPrimary),
            onChanged: (_) {
              setState(() {});
              _updatePending();
            },
          ),
        ),
        const SizedBox(width: 10),
        if ((_amount - widget.initialAmount).abs() >= 1)
          Text(
            'Δ ${_amount - widget.initialAmount >= 0 ? '+' : '-'}${(_amount - widget.initialAmount).abs().toINRCompact()}',
            style: TextStyle(
                fontSize: 11,
                color: _amount > widget.initialAmount
                    ? AppColors.gain
                    : AppColors.loss),
          )
        else
          Text(
            'Suggested ${widget.initialAmount.toINRCompact()}',
            style: TextStyle(fontSize: 11, color: palette.textTertiary),
          ),
      ],
    );
  }

  /// Post-move concentration of the destination fund inside its bucket.
  /// Returns null when we can't compute (no bucket total or no destination).
  Widget? _concentrationWarning() {
    final bucketPre = widget.toBucketCurrentValue;
    if (bucketPre == null || _toAmfi == null) return null;
    final destCurrent = widget.destinationOptions
            .firstWhere(
              (h) => h.amfiCode == _toAmfi,
              orElse: () => const FundHoldingSummary(
                  amfiCode: 0, fundName: '', currentValue: 0),
            )
            .currentValue;
    final amount = _amount;
    final bucketPost = bucketPre + amount;
    if (bucketPost <= 0) return null;
    final destPost = destCurrent + amount;
    final pct = destPost / bucketPost * 100.0;
    if (pct <= widget.concentrationLimitPct) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber,
              size: 12, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Concentration: $_toName would be ${pct.toStringAsFixed(0)}% '
              'of ${widget.toBucket.displayName} post-move '
              '(cap ${widget.concentrationLimitPct.toStringAsFixed(0)}%).',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
            onPressed: widget.busy ? null : widget.onSave,
            child: const Text('Save')),
        const SizedBox(width: 4),
        TextButton(
            onPressed: widget.busy ? null : widget.onDismiss,
            child: const Text('Dismiss')),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: widget.busy
              ? null
              : () => widget.onExecute(_toAmfi, _toName, _amount),
          child: const Text('Execute'),
        ),
      ],
    );
  }
}

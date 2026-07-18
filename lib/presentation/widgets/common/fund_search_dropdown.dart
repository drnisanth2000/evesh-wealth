import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/fund_model.dart';
import '../../providers/fund_provider.dart';

/// Typeahead fund search — inline results list, no overlay.
class FundSearchDropdown extends ConsumerStatefulWidget {
  const FundSearchDropdown({
    super.key,
    required this.onSelected,
    this.initialFund,
    this.hintText = 'Search fund name...',
    this.enabled = true,
  });

  final void Function(FundModel fund) onSelected;
  final FundModel? initialFund;
  final String hintText;
  final bool enabled;

  @override
  ConsumerState<FundSearchDropdown> createState() => _FundSearchDropdownState();
}

class _FundSearchDropdownState extends ConsumerState<FundSearchDropdown> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _showResults = false;
  bool _programmaticChange = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFund != null) {
      _controller.text = widget.initialFund!.fundName;
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && mounted) {
        // Small delay so tap on result registers before hiding
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showResults = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFundSelected(FundModel fund) {
    _programmaticChange = true;
    _controller.text = fund.fundName;
    _programmaticChange = false;
    setState(() {
      _query = '';
      _showResults = false;
    });
    widget.onSelected(fund);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Search input ────────────────────────────────────────────────────
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: (v) {
            if (_programmaticChange) return;
            setState(() {
              _query = v;
              _showResults = v.trim().length >= 2;
            });
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _query = '';
                        _showResults = false;
                      });
                    },
                  )
                : null,
          ),
        ),

        // ── Inline results ──────────────────────────────────────────────────
        if (_showResults) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: context.palette.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.palette.bgDivider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _FundResultsList(
              query: _query,
              onSelected: _onFundSelected,
            ),
          ),
        ],
      ],
    );
  }
}

class _FundResultsList extends ConsumerWidget {
  const _FundResultsList({required this.query, required this.onSelected});
  final String query;
  final void Function(FundModel) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsAsync = ref.watch(fundSearchProvider(query));

    return fundsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e',
            style: TextStyle(color: context.palette.loss, fontSize: 13)),
      ),
      data: (funds) {
        if (funds.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Text('No funds found',
                style: TextStyle(color: context.palette.textTertiary, fontSize: 13)),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: funds.length,
          itemBuilder: (_, i) {
            final f = funds[i];
            return InkWell(
              onTap: () => onSelected(f),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.fundName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (f.category != null) _Tag(f.category!),
                        if (f.planType != null) ...[
                          const SizedBox(width: 4),
                          _Tag(f.planType!, color: AppColors.primary),
                        ],
                        const Spacer(),
                        if (f.latestNav != null)
                          Text(
                            'NAV ₹${f.latestNav!.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 11, color: context.palette.textTertiary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, color: c)),
    );
  }
}

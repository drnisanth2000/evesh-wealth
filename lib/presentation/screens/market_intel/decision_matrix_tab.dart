import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/screener_models.dart';
import '../../providers/decision_matrix_provider.dart';
import '../../providers/family_provider.dart';

class DecisionMatrixTab extends ConsumerStatefulWidget {
  const DecisionMatrixTab({super.key});

  @override
  ConsumerState<DecisionMatrixTab> createState() => _DecisionMatrixTabState();
}

class _DecisionMatrixTabState extends ConsumerState<DecisionMatrixTab> {
  double _amount = 1000000;
  int _horizonYears = 5;
  double _taxSlabPct = 30;
  bool _isNewRegime = false;
  bool _taxSlabInitialized = false;

  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '1000000');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pick tax slab from selfMember on first load
    if (!_taxSlabInitialized) {
      final selfAsync = ref.watch(selfMemberProvider);
      selfAsync.whenOrNull(
        data: (member) {
          if (!_taxSlabInitialized) {
            setState(() {
              _taxSlabPct = member?.taxSlabPct ?? 30;
              _taxSlabInitialized = true;
            });
          }
        },
      );
    }

    final input = DecisionMatrixInput(
      amount: _amount,
      horizonYears: _horizonYears,
      taxSlabPct: _taxSlabPct,
      isNewRegime: _isNewRegime,
    );

    final result = ref.watch(decisionMatrixProvider(input));

    // Group rows by category
    final Map<String, List<DecisionMatrixRow>> grouped = {};
    for (final row in result.rows) {
      (grouped[row.category] ??= []).add(row);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Input card ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.palette.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.palette.bgDivider),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Investment Parameters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount field
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    labelStyle: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: context.palette.bgSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setState(() => _amount = parsed);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Horizon
                Text(
                  'Horizon',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: [1, 3, 5, 10].map((y) {
                    return ButtonSegment<int>(
                      value: y,
                      label: Text('${y}Y'),
                    );
                  }).toList(),
                  selected: {_horizonYears},
                  onSelectionChanged: (s) =>
                      setState(() => _horizonYears = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return context.palette.bgSurface;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.textOnPrimary;
                      }
                      return context.palette.textSecondary;
                    }),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tax slab
                Row(
                  children: [
                    Text(
                      'Tax Slab',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<double>(
                      value: _taxSlabPct,
                      dropdownColor: context.palette.bgCardElevated,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textPrimary,
                      ),
                      underline: const SizedBox(),
                      onChanged: (v) {
                        if (v != null) setState(() => _taxSlabPct = v);
                      },
                      items: [0, 5, 10, 15, 20, 25, 30]
                          .map((n) => DropdownMenuItem<double>(
                                value: n.toDouble(),
                                child: Text('$n%'),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Regime toggle
                Row(
                  children: [
                    Text(
                      'Tax Regime',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(value: false, label: Text('Old')),
                        ButtonSegment<bool>(value: true, label: Text('New')),
                      ],
                      selected: {_isNewRegime},
                      onSelectionChanged: (s) =>
                          setState(() => _isNewRegime = s.first),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return context.palette.bgSurface;
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.textOnPrimary;
                          }
                          return context.palette.textSecondary;
                        }),
                        textStyle: WidgetStateProperty.all(
                          const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Results grouped by category ─────────────────────────────────────
          ...grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...entry.value.map((row) => _MatrixRowCard(
                      row: row,
                      amount: _amount,
                    )),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Individual row card ───────────────────────────────────────────────────────

class _MatrixRowCard extends StatelessWidget {
  const _MatrixRowCard({
    required this.row,
    required this.amount,
  });

  final DecisionMatrixRow row;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final netColor =
        row.netReturn >= 0 ? AppColors.gain : AppColors.loss;

    final maturityFormatted = row.maturityValue.toINRCompact();
    final amountFormatted = amount.toINRCompact();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.bgDivider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: name + trailing returns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading: instrument name + note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.instrument,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.palette.textPrimary,
                        ),
                      ),
                      if (row.note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.note!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Trailing: net return + maturity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.netReturn.toPercent(decimals: 1, showSign: true),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$amountFormatted → $maturityFormatted',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Chips row
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Chip(
                  label: '${row.grossReturn.toPercent(decimals: 1)} gross',
                  color: context.palette.textSecondary,
                  bgColor: context.palette.bgSurface,
                ),
                _Chip(
                  label:
                      '-${row.taxImpact.abs().toPercent(decimals: 1)} tax',
                  color: AppColors.loss,
                  bgColor: AppColors.loss.withValues(alpha: 0.12),
                ),
                _Chip(
                  label: row.taxTreatment,
                  color: context.palette.textTertiary,
                  bgColor: context.palette.bgSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

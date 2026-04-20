import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Horizontal chip selector for asset types.
/// Only shows types present in [availableTypes].
/// Calls [onSelected] with null for "All" or a db value like "MF", "Stock".
class AssetTypeSelector extends StatelessWidget {
  const AssetTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
    required this.availableTypes,
  });

  final String? selectedType;
  final void Function(String?) onSelected;
  final Set<String> availableTypes;

  static const _typeLabels = {
    'MF': 'MF',
    'Stock': 'Stocks',
    'PMS': 'PMS',
    'Gold': 'Gold',
    'RealEstate': 'Real Estate',
    'SGB': 'SGB',
    'REIT': 'REIT',
    'InvIT': 'InvIT',
    'FD': 'FD',
    'PPF': 'PPF',
    'NPS': 'NPS',
    'AIF': 'AIF',
    'SIF': 'SIF',
    'Other': 'Other',
  };

  static const _typeIcons = {
    'MF': Icons.show_chart,
    'Stock': Icons.candlestick_chart_outlined,
    'PMS': Icons.account_balance_wallet_outlined,
    'Gold': Icons.diamond_outlined,
    'RealEstate': Icons.home_outlined,
    'SGB': Icons.savings_outlined,
    'REIT': Icons.business_outlined,
    'InvIT': Icons.factory_outlined,
    'FD': Icons.lock_clock_outlined,
    'PPF': Icons.shield_outlined,
    'NPS': Icons.elderly_outlined,
    'AIF': Icons.trending_up_outlined,
    'SIF': Icons.pie_chart_outline,
    'Other': Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (availableTypes.isEmpty) return const SizedBox.shrink();

    // Order types consistently
    final ordered = _typeLabels.keys
        .where((t) => availableTypes.contains(t))
        .toList();

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _TypeChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            selected: selectedType == null,
            onTap: () => onSelected(null),
          ),
          ...ordered.map((type) => _TypeChip(
                label: _typeLabels[type] ?? type,
                icon: _typeIcons[type] ?? Icons.category_outlined,
                selected: selectedType == type,
                onTap: () => onSelected(type),
              )),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : context.palette.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : context.palette.bgDivider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.primary : context.palette.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

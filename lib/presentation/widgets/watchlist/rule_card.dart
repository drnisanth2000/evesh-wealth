import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/watchlist_rule_model.dart';
import '../../providers/watchlist_provider.dart';

class RuleCard extends ConsumerWidget {
  const RuleCard({
    super.key,
    required this.rule,
    this.currentNav,
    required this.onTap,
    required this.onDelete,
    required this.onToggle,
  });

  final WatchlistRuleModel rule;
  final double? currentNav;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  // Returns (status label, color) based on rule type + current nav
  ({String label, Color color}) _status(BuildContext context) {
    final nav = currentNav;
    final threshold = rule.thresholdValue;

    if (nav == null || rule.thresholdType != 'nav') {
      return (label: 'Monitoring', color: context.palette.textTertiary);
    }

    switch (rule.ruleType) {
      case 'stop_loss':
        if (nav <= threshold) {
          return (label: 'Breached', color: AppColors.loss);
        }
        final buffer = nav - threshold;
        final pct = (buffer / nav * 100);
        if (pct < 5) {
          return (label: 'Near ₹${nav.toStringAsFixed(2)}', color: AppColors.warning);
        }
        return (label: 'Safe ₹${nav.toStringAsFixed(2)}', color: AppColors.gain);

      case 'gain_harvest':
      case 'price_target':
        if (nav >= threshold) {
          return (label: 'Breached', color: AppColors.loss);
        }
        final distance = threshold - nav;
        final pct = (distance / threshold * 100);
        if (pct < 5) {
          return (label: 'Near ₹${nav.toStringAsFixed(2)}', color: AppColors.warning);
        }
        return (label: 'Safe ₹${nav.toStringAsFixed(2)}', color: AppColors.gain);

      default:
        return (label: 'Monitoring', color: context.palette.textTertiary);
    }
  }

  Color _badgeColor(BuildContext context) {
    switch (rule.ruleType) {
      case 'stop_loss':
        return AppColors.loss;
      case 'gain_harvest':
        return AppColors.gain;
      case 'price_target':
        return AppColors.primary;
      case 'allocation_drift':
        return AppColors.warning;
      default:
        return context.palette.textTertiary;
    }
  }

  String get _title {
    if (rule.ruleType == 'allocation_drift') {
      return rule.assetClassKey ?? 'Portfolio';
    }
    return rule.fundName ?? 'Unknown Fund';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = _status(context);

    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.loss.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.loss, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.palette.bgCard,
            title: Text('Delete Rule',
                style: TextStyle(color: context.palette.textPrimary)),
            content: Text(
              'Delete "${rule.ruleTypeLabel}" rule for $_title?',
              style: TextStyle(color: context.palette.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel',
                    style: TextStyle(color: context.palette.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.loss)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.bgDivider),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: fund info + badge ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fund name / asset class
                    Text(
                      _title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.palette.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Rule type badge + description
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _badgeColor(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rule.ruleTypeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _badgeColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            rule.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (rule.note != null && rule.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        rule.note!,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Right: status + toggle ─────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status label
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Active toggle
                  Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.centerRight,
                    child: Switch(
                      value: rule.isActive,
                      onChanged: rule.isActive == false && !ref.watch(watchlistNotifierProvider).isLoading
                          ? (v) => onToggle(v)
                          : (v) => onToggle(v),
                      activeColor: AppColors.primary,
                      inactiveThumbColor: context.palette.textTertiary,
                      inactiveTrackColor: context.palette.bgDivider,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

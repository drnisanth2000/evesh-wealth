import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/extensions/number_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/action_models.dart';
import '../../../core/constants/platform_links.dart';

/// A single action item card with checkbox, impact, and platform links.
class ActionItemCard extends StatelessWidget {
  const ActionItemCard({
    super.key,
    required this.item,
    required this.onToggle,
  });

  final ActionItem item;
  final VoidCallback onToggle;

  Color get _priorityColor {
    switch (item.priority) {
      case ActionPriority.critical:
        return AppColors.loss;
      case ActionPriority.warning:
        return AppColors.warning;
      case ActionPriority.info:
        return AppColors.info;
    }
  }

  IconData get _sourceIcon {
    switch (item.source) {
      case ActionSource.rebalance:
        return Icons.swap_horiz;
      case ActionSource.retirement:
        return Icons.elderly;
      case ActionSource.drift:
        return Icons.warning_amber;
      case ActionSource.cashOptimization:
        return Icons.savings;
      case ActionSource.fundReplace:
        return Icons.find_replace;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.bgCard,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _priorityColor.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority color bar
              Container(
                width: 3,
                height: 60,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),

              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: item.isCompleted,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.gain,
                  side: BorderSide(color: _priorityColor),
                ),
              ),
              const SizedBox(width: 8),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.isCompleted
                            ? context.palette.textTertiary
                            : context.palette.textPrimary,
                        decoration:
                            item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      item.subtitle,
                      style: TextStyle(
                          fontSize: 11, color: context.palette.textTertiary),
                    ),
                    const SizedBox(height: 6),

                    // Impact chip + source icon
                    Row(
                      children: [
                        Icon(_sourceIcon, size: 12, color: _priorityColor),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _priorityColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.impactDescription,
                            style: TextStyle(
                                fontSize: 10,
                                color: _priorityColor,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (item.amount != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.amount!.toINR(compact: true),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _priorityColor),
                          ),
                        ],
                      ],
                    ),

                    // Platform links
                    if (item.platformLinks.isNotEmpty && !item.isCompleted) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: item.platformLinks.take(4).map((link) {
                          final config = PlatformLinks.platforms[link.platform];
                          return InkWell(
                            onTap: () => _launchUrl(link.url),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: context.palette.bgDivider),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(config?.icon ?? Icons.open_in_new,
                                      size: 10, color: context.palette.textTertiary),
                                  const SizedBox(width: 3),
                                  Text(
                                    config?.name ?? link.label,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: context.palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Section header for grouped action items.
class ActionSourceHeader extends StatelessWidget {
  const ActionSourceHeader({super.key, required this.source, required this.count});

  final ActionSource source;
  final int count;

  String get _label {
    switch (source) {
      case ActionSource.rebalance:
        return 'Rebalance Required';
      case ActionSource.retirement:
        return 'Retirement Gap';
      case ActionSource.drift:
        return 'Drift Alerts';
      case ActionSource.cashOptimization:
        return 'Cash Optimization';
      case ActionSource.fundReplace:
        return 'Fund Replacement';
    }
  }

  Color get _color {
    switch (source) {
      case ActionSource.rebalance:
        return AppColors.loss;
      case ActionSource.retirement:
        return AppColors.info;
      case ActionSource.drift:
        return AppColors.warning;
      case ActionSource.cashOptimization:
        return AppColors.gain;
      case ActionSource.fundReplace:
        return AppColors.loss;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _color),
            ),
          ),
        ],
      ),
    );
  }
}

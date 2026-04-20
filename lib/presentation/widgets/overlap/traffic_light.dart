import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/overlap_models.dart';

/// Traffic light indicator: shows risk level as emoji + percentage + label
///
/// Supports compact mode for inline use:
/// - Normal: Full height widget with centered layout
/// - Compact: Single-line inline indicator (emoji + percentage)
///
/// Example:
/// ```dart
/// TrafficLight(
///   risk: RiskLevel.high,
///   percentage: 28.5,
///   compact: false,
/// )
/// ```
class TrafficLight extends StatelessWidget {
  final RiskLevel risk;
  final double percentage;
  final bool compact;
  final VoidCallback? onTap;

  const TrafficLight({
    Key? key,
    required this.risk,
    required this.percentage,
    this.compact = false,
    this.onTap,
  }) : super(key: key);

  String _getEmoji(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => '🟢',
      RiskLevel.moderate => '🟡',
      RiskLevel.high => '🔴',
    };
  }

  String _getLabel(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.moderate => 'Moderate Risk',
      RiskLevel.high => 'High Risk',
    };
  }

  Color _getColor(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => AppColors.gain,
      RiskLevel.moderate => AppColors.warning,
      RiskLevel.high => AppColors.loss,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Text(_getEmoji(risk), style: const TextStyle(fontSize: 16)),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getColor(risk),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_getEmoji(risk), style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _getColor(risk),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _getLabel(risk),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Portfolio health badge: full-width banner showing overall risk level + issue count
///
/// Displays:
/// - Overall risk level (Low/Moderate/High)
/// - Count of issues detected
/// - Color-coded background based on risk
///
/// Example:
/// ```dart
/// PortfolioHealthBadge(
///   risk: RiskLevel.high,
///   issueCount: 3,
///   onTap: () => showDetails(),
/// )
/// ```
class PortfolioHealthBadge extends StatelessWidget {
  final RiskLevel risk;
  final int issueCount;
  final VoidCallback? onTap;

  const PortfolioHealthBadge({
    Key? key,
    required this.risk,
    required this.issueCount,
    this.onTap,
  }) : super(key: key);

  String _getEmoji(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => '🟢',
      RiskLevel.moderate => '🟡',
      RiskLevel.high => '🔴',
    };
  }

  String _getLabel(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.moderate => 'Moderate Risk',
      RiskLevel.high => 'High Risk',
    };
  }

  Color _getBgColor(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => AppColors.alertLowBg,
      RiskLevel.moderate => AppColors.alertMediumBg,
      RiskLevel.high => AppColors.alertUrgentBg,
    };
  }

  Color _getBorderColor(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => AppColors.alertLow,
      RiskLevel.moderate => AppColors.alertMedium,
      RiskLevel.high => AppColors.alertUrgent,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBgColor(risk),
          border: Border.all(
            color: _getBorderColor(risk),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 12,
              children: [
                Text(_getEmoji(risk), style: const TextStyle(fontSize: 24)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLabel(risk),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      issueCount == 1
                          ? '1 issue found'
                          : '$issueCount issues found',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: _getBorderColor(risk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delta indicator: shows pre-buy impact with before → after risk shift
///
/// Format: "22% → 28% 🟡→🔴"
/// Supports both sector and stock deltas
///
/// Example:
/// ```dart
/// DeltaIndicator(
///   label: 'TCS',
///   beforePct: 22.0,
///   afterPct: 28.0,
///   beforeRisk: RiskLevel.moderate,
///   afterRisk: RiskLevel.high,
/// )
/// ```
class DeltaIndicator extends StatelessWidget {
  final String label;
  final double beforePct;
  final double afterPct;
  final RiskLevel beforeRisk;
  final RiskLevel afterRisk;

  const DeltaIndicator({
    Key? key,
    required this.label,
    required this.beforePct,
    required this.afterPct,
    required this.beforeRisk,
    required this.afterRisk,
  }) : super(key: key);

  String _getEmoji(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => '🟢',
      RiskLevel.moderate => '🟡',
      RiskLevel.high => '🔴',
    };
  }

  Color _getColor(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => AppColors.gain,
      RiskLevel.moderate => AppColors.warning,
      RiskLevel.high => AppColors.loss,
    };
  }

  bool get _riskIncreased => afterRisk.index > beforeRisk.index;

  @override
  Widget build(BuildContext context) {
    final beforeColor = _getColor(beforeRisk);
    final afterColor = _getColor(afterRisk);
    final isWarning = _riskIncreased;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.alertUrgentBg
            : context.palette.bgSurface,
        border: Border.all(
          color: isWarning
              ? AppColors.alertUrgent.withValues(alpha: 0.3)
              : context.palette.textTertiary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            '${beforePct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: beforeColor,
                ),
          ),
          Text(
            _getEmoji(beforeRisk),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            '→',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.palette.textTertiary,
                ),
          ),
          Text(
            '${afterPct.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: afterColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            _getEmoji(afterRisk),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

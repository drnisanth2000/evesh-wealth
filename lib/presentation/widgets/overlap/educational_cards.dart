import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

/// Collapsible educational card with icon + title + expandable body
///
/// Example:
/// ```dart
/// EducationalCard(
///   icon: Icons.info,
///   title: 'Why does fund overlap matter?',
///   body: 'Fund overlap can hide concentration risk...',
/// )
/// ```
class EducationalCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;
  final bool initiallyExpanded;

  const EducationalCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<EducationalCard> createState() => _EducationalCardState();
}

class _EducationalCardState extends State<EducationalCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.bgCard,
        border: Border.all(
          color: context.palette.bgDivider,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (widget.iconColor ?? AppColors.info).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              color: widget.iconColor ?? AppColors.info,
              size: 20,
            ),
          ),
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: context.palette.textSecondary,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                widget.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.palette.textSecondary,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-built set of 3 educational cards explaining overlap and concentration risk
///
/// Includes:
/// 1. "Why does fund overlap matter?" — explains hidden concentration risk
/// 2. "SEBI's 50% overlap rule (2026)" — explains the Feb 2026 mandate
/// 3. "Stock concentration risk" — explains the 20/25 rule and portfolio-level risk
///
/// Example:
/// ```dart
/// OverlapEducation()
/// ```
class OverlapEducation extends StatelessWidget {
  final bool initiallyExpanded;

  const OverlapEducation({
    Key? key,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 0,
      children: [
        EducationalCard(
          icon: Icons.info_outline,
          iconColor: AppColors.info,
          title: 'Why does fund overlap matter?',
          body: '''Fund overlap occurs when multiple funds in your portfolio hold the same stocks. This creates hidden concentration risk—even though you own "diversified" funds, you might actually be heavily exposed to just a few companies.

Example: If your Equity Fund A holds 5% in TCS and Equity Fund B holds 8% in TCS, your effective exposure to TCS is not the average but the sum of both weighted by fund allocation.

This defeats the purpose of owning multiple funds. SEBI's 2026 regulations now mandate that fund managers publish overlap metrics quarterly.''',
          initiallyExpanded: initiallyExpanded,
        ),
        EducationalCard(
          icon: Icons.rule_outlined,
          iconColor: AppColors.warning,
          title: 'SEBI\'s 50% overlap rule (2026)',
          body: '''In February 2026, SEBI introduced a new mandate: No two funds in a portfolio can have more than 50% stock overlap.

This rule applies to:
• Funds with similar investment mandates (both Large Cap, both Mid Cap, etc.)
• Funds in the same category (e.g., Balanced Advantage)

Why? To ensure that owning multiple funds actually gives you diversification, not redundancy.

Your portfolio is checked quarterly against this threshold. If overlap exceeds 50%, you may face restrictions on further investing or forced rebalancing.''',
          initiallyExpanded: initiallyExpanded,
        ),
        EducationalCard(
          icon: Icons.trending_up,
          iconColor: context.palette.gain,
          title: 'Stock concentration risk',
          body: '''Even with overlap control, individual stock concentration can sink a portfolio.

SEBI's 20/25 rule limits individual stock exposure:
• No single stock > 20% of portfolio value
• No top 25 stocks > 60% of portfolio value

These are hard limits. If your eVesh portfolio violates these, rebalancing is urgent.

Additionally, eVesh warns if any stock exceeds 12% (yellow) or 18% (red). These internal thresholds give you early warning before hitting SEBI's hard 20% limit.

Check your stock concentration monthly and diversify if needed.''',
          initiallyExpanded: initiallyExpanded,
        ),
      ],
    );
  }
}

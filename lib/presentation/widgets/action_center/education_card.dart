import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/models/simulation_models.dart';

/// Expandable card showing 3-bucket strategy education tips.
/// Context-sensitive: renders different titles/content for
/// accumulation vs distribution scenarios.
class EducationCard extends StatefulWidget {
  const EducationCard({super.key, required this.strategy});

  final BucketStrategy strategy;

  @override
  State<EducationCard> createState() => _EducationCardState();
}

class _EducationCardState extends State<EducationCard> {
  bool _expanded = false;

  String get _title => widget.strategy.scenario == 'distribution'
      ? 'Retirement Bucket Strategy'
      : 'Wealth Building Bucket Strategy';

  @override
  Widget build(BuildContext context) {
    final notes = widget.strategy.educationNotes;
    final rules = widget.strategy.refillRules;

    final firstNote = notes.isNotEmpty ? notes.first : null;
    final remainingNotes = notes.length > 1 ? notes.sublist(1) : <String>[];

    return Card(
      color: context.palette.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.info.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppColors.info.withValues(alpha: 0.80),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: context.palette.textTertiary,
                  ),
                ],
              ),

              // ── First note (always visible) ──────────────────────────────
              if (firstNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  firstNote,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],

              // ── Expanded content ─────────────────────────────────────────
              if (_expanded) ...[
                // Remaining notes with check icons
                if (remainingNotes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...remainingNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.check_circle,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Refill rules section
                if (rules.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Divider(
                    color: context.palette.bgDivider,
                    thickness: 1,
                    height: 1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Refill Rules',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.swap_vert,
                              size: 12,
                              color: AppColors.warning.withValues(alpha: 0.80),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rule.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rule.frequency,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.warning.withValues(alpha: 0.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

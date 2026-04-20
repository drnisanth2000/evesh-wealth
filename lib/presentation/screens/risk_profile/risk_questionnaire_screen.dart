// lib/presentation/screens/risk_profile/risk_questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/risk_questionnaire.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../domain/usecases/compute_risk_score.dart';
import '../../providers/risk_profile_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/risk_profile/risk_meter.dart';

/// Total pages in the quiz: 6 questions + 1 demographics page.
const int _kTotalSteps = 7;

/// Step index (0-based) at which the demographics page lives.
const int _kDemographicsStep = 6; // pages 1..6 = questions, page 7 = demo

class RiskQuestionnaireScreen extends ConsumerStatefulWidget {
  const RiskQuestionnaireScreen({super.key, this.memberId});
  final String? memberId;

  @override
  ConsumerState<RiskQuestionnaireScreen> createState() =>
      _RiskQuestionnaireScreenState();
}

class _RiskQuestionnaireScreenState
    extends ConsumerState<RiskQuestionnaireScreen> {
  RiskLocale _locale = RiskLocale.en;

  /// 0..6 → quiz steps; when a result is set, the screen swaps to result view.
  int _step = 0;

  final List<int?> _answers = List<int?>.filled(riskQuestions.length, null);
  final Map<String, String> _demographics = {};

  RiskScoreResult? _result;

  bool get _currentStepAnswered {
    if (_step < _kDemographicsStep) return _answers[_step] != null;
    // Demographics page requires every field (income is conditional on age).
    return demographicFields.every(
      (f) => _demographics.containsKey(f.id.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) return _buildResultScaffold(context, _result!);

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _locale =
                _locale == RiskLocale.en ? RiskLocale.hi : RiskLocale.en),
            child: Text(
              _locale == RiskLocale.en ? 'हिंदी' : 'English',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBlock(context),
              const SizedBox(height: 16),
              _buildQuizCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header block (title + subtitle, sits on light background) ─────────

  Widget _buildHeaderBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _locale == RiskLocale.hi ? 'जोखिम प्रवृत्ति' : 'Risk Appetite',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _locale == RiskLocale.hi
                ? 'अपनी आवश्यकताओं के लिए सही एसेट एलोकेशन समझना निवेश यात्रा का पहला महत्वपूर्ण कदम है।'
                : 'Understanding the right asset allocation for your needs is a crucial step before you begin your investment journey.',
            style: TextStyle(
              fontSize: 13,
              color: context.palette.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quiz card (white container on light background) ──────────────────

  Widget _buildQuizCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressRow(context),
          const SizedBox(height: 24),
          if (_step < _kDemographicsStep)
            _buildQuestionBody(context, _step)
          else
            _buildDemographicsBody(context),
          const SizedBox(height: 24),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            _locale == RiskLocale.hi
                ? 'आइए आपकी जोखिम प्रवृत्ति मापें'
                : 'LETS CALCULATE YOUR RISK APPETITE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_step + 1) / _kTotalSteps,
              minHeight: 6,
              backgroundColor: context.palette.bgDivider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_step + 1}/$_kTotalSteps',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary),
        ),
      ],
    );
  }

  // ── Question page (steps 0..5) ────────────────────────────────────────

  Widget _buildQuestionBody(BuildContext context, int step) {
    final q = riskQuestions[step];
    final selected = _answers[step];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${step + 1}. ${q.prompt(_locale)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.palette.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        ...q.options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          final isSel = selected == idx;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _answers[step] = idx),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSel
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSel
                          ? AppColors.primary
                          : context.palette.textTertiary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.label(_locale),
                        style: TextStyle(
                          fontSize: 15,
                          color: context.palette.textPrimary,
                          fontWeight:
                              isSel ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Demographics page (step 6) ────────────────────────────────────────

  Widget _buildDemographicsBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _locale == RiskLocale.hi
              ? 'जनसांख्यिकी स्कोर की गणना करें'
              : 'Calculate demographic score',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        // 2-column grid: split the 7 fields into two columns.
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 520;
            final fields = _orderedDemographicFieldsForDisplay();
            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields.map((f) => _demographicBlock(context, f)).toList(),
              );
            }
            // Interleave into two columns: left = 0,2,4,6 ; right = 1,3,5
            final left = <Widget>[];
            final right = <Widget>[];
            for (var i = 0; i < fields.length; i++) {
              (i.isEven ? left : right).add(_demographicBlock(context, fields[i]));
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: left)),
                const SizedBox(width: 24),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: right)),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Returns demographic fields in display order. Income must follow age
  /// group because its options depend on the age selection.
  List<DemographicField> _orderedDemographicFieldsForDisplay() {
    return [
      _byId(DemographicFieldId.gender),
      _byId(DemographicFieldId.ageGroup),
      _byId(DemographicFieldId.income),
      _byId(DemographicFieldId.workType),
      _byId(DemographicFieldId.education),
      _byId(DemographicFieldId.investingExperience),
      _byId(DemographicFieldId.investmentDuration),
    ];
  }

  DemographicField _byId(DemographicFieldId id) =>
      demographicFields.firstWhere((f) => f.id == id);

  Widget _demographicBlock(BuildContext context, DemographicField f) {
    List<DemographicOption> opts = f.options;
    if (f.id == DemographicFieldId.income) {
      final ageVal = _demographics[DemographicFieldId.ageGroup.name];
      if (ageVal == null) {
        // Before age is picked, show the under-60 income options as
        // placeholder (disabled).
        opts = incomeOptionsFor('under60');
      } else {
        opts = incomeOptionsFor(ageVal);
      }
    }

    final current = _demographics[f.id.name];
    final ageMissing = f.id == DemographicFieldId.income &&
        !_demographics.containsKey(DemographicFieldId.ageGroup.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            f.prompt(_locale),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: opts.map((o) {
              final isSel = current == o.value;
              return _DemoChip(
                label: o.label(_locale),
                selected: isSel,
                enabled: !ageMissing,
                onTap: () => setState(() {
                  _demographics[f.id.name] = o.value;
                  if (f.id == DemographicFieldId.ageGroup) {
                    // Clear a stale income selection when age changes.
                    _demographics.remove(DemographicFieldId.income.name);
                  }
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Nav buttons (Back / Continue) ─────────────────────────────────────

  Widget _buildNavButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: _onBack,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            _locale == RiskLocale.hi ? 'पीछे' : 'BACK',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _currentStepAnswered ? _onContinue : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor:
                AppColors.primary.withValues(alpha: 0.45),
            padding:
                const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            _locale == RiskLocale.hi ? 'आगे' : 'CONTINUE',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _onBack() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  void _onContinue() {
    if (_step < _kDemographicsStep) {
      setState(() => _step++);
      return;
    }
    // Final step → compute and switch to result view.
    final result = computeRiskScore(
      answerIndices: _answers.cast<int>(),
      demographics: Map<String, String>.from(_demographics),
    );
    setState(() => _result = result);
  }

  // ── Result view ───────────────────────────────────────────────────────

  Widget _buildResultScaffold(BuildContext context, RiskScoreResult r) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _locale == RiskLocale.hi ? 'आपकी जोखिम प्रवृत्ति' : 'Your Risk Appetite',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: context.palette.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                r.tier.dbValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: r.tier.color),
              ),
              const SizedBox(height: 6),
              Text(
                'Q-score: ${r.phase1Score}  •  Profile adj: ${r.phase2Adjustment >= 0 ? '+' : ''}${r.phase2Adjustment}  •  Total: ${r.totalScore}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: context.palette.textTertiary),
              ),
              const SizedBox(height: 24),
              Center(child: RiskMeter(tier: r.tier)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: r.tier.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _locale == RiskLocale.hi
                      ? r.tier.educationHi
                      : r.tier.educationEn,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Please note that this score is an estimate based on the responses you provided. This is a mathematical calculation from your inputs only — returns are neither assured nor guaranteed. Please consult a qualified financial advisor before taking any investment decisions.',
                style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textTertiary,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _result = null;
                        _step = 0;
                        for (var i = 0; i < _answers.length; i++) {
                          _answers[i] = null;
                        }
                        _demographics.clear();
                      }),
                      child: Text(
                        _locale == RiskLocale.hi ? 'फिर से' : 'Retake',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(riskProfileMutatorProvider.notifier)
                              .saveFromQuestionnaire(
                                memberId: widget.memberId,
                                answers: _answers.cast<int>(),
                                demographics:
                                    Map<String, String>.from(_demographics),
                                result: r,
                              );
                          if (!mounted) return;
                          context.go(Routes.riskProfile);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Save failed: $e')),
                          );
                        }
                      },
                      child: Text(
                        _locale == RiskLocale.hi
                            ? 'स्वीकार करें'
                            : 'Accept & Save',
                      ),
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

// ─── Demographic chip button (matches reference UI) ─────────────────────

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : context.palette.textPrimary;
    final border = selected ? AppColors.primary : context.palette.bgDivider;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 1.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

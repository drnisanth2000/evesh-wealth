// lib/core/constants/risk_questionnaire.dart
//
// Two-phase internal risk profiler. Everything in this file stays local —
// no external APIs, no third-party calls.

enum RiskLocale { en, hi }

// ─── Phase 1: Risk Appetite Questions ────────────────────────────────────

class RiskQuestion {
  const RiskQuestion({
    required this.id,
    required this.promptEn,
    required this.promptHi,
    required this.options,
  });
  final String id;
  final String promptEn;
  final String promptHi;
  final List<RiskOption> options;

  String prompt(RiskLocale loc) => loc == RiskLocale.hi ? promptHi : promptEn;
}

class RiskOption {
  const RiskOption({
    required this.labelEn,
    required this.labelHi,
    required this.score,
  });
  final String labelEn;
  final String labelHi;
  final int score; // 20 / 40 / 60 / 80

  String label(RiskLocale loc) => loc == RiskLocale.hi ? labelHi : labelEn;
}

const riskQuestions = <RiskQuestion>[
  RiskQuestion(
    id: 'q1_first_instinct',
    promptEn: 'When you put your money into an investment, what\'s the first thing you think?',
    promptHi: 'जब आप अपना पैसा निवेश करते हैं, तो सबसे पहले आपके मन में क्या आता है?',
    options: [
      RiskOption(
        labelEn: 'I don\'t want to lose my money.',
        labelHi: 'मैं अपना पैसा नहीं खोना चाहता।',
        score: 20,
      ),
      RiskOption(
        labelEn: 'I hope this doesn\'t turn out to be a bad choice.',
        labelHi: 'मुझे उम्मीद है यह गलत फैसला न हो।',
        score: 40,
      ),
      RiskOption(
        labelEn: 'I think this will give me good returns.',
        labelHi: 'मुझे लगता है यह अच्छा रिटर्न देगा।',
        score: 60,
      ),
      RiskOption(
        labelEn: 'I\'m sure this is a smart choice.',
        labelHi: 'मुझे पक्का यकीन है कि यह एक समझदारी भरा फैसला है।',
        score: 80,
      ),
    ],
  ),
  RiskQuestion(
    id: 'q2_word_association',
    promptEn: 'When you hear the word \'risk\', what is the first thing that comes to mind?',
    promptHi: 'जब आप \'जोखिम\' शब्द सुनते हैं, तो सबसे पहले आपके मन में क्या आता है?',
    options: [
      RiskOption(labelEn: 'Danger', labelHi: 'ख़तरा', score: 20),
      RiskOption(labelEn: 'Not sure what will happen', labelHi: 'पक्का नहीं कि क्या होगा', score: 40),
      RiskOption(labelEn: 'A chance to gain', labelHi: 'फ़ायदा कमाने का मौका', score: 60),
      RiskOption(labelEn: 'Excitement', labelHi: 'रोमांच', score: 80),
    ],
  ),
  RiskQuestion(
    id: 'q3_work_style',
    promptEn: 'If you could pick your dream job, which one sounds best?',
    promptHi: 'अगर आप अपना पसंदीदा काम चुन सकते, तो कौन सा सबसे अच्छा लगेगा?',
    options: [
      RiskOption(
        labelEn: 'A steady job with a fixed monthly salary.',
        labelHi: 'हर महीने तय वेतन वाली पक्की नौकरी।',
        score: 20,
      ),
      RiskOption(
        labelEn: 'A job with a small side business.',
        labelHi: 'नौकरी के साथ एक छोटा व्यवसाय।',
        score: 40,
      ),
      RiskOption(
        labelEn: 'A business with a trusted partner.',
        labelHi: 'किसी भरोसेमंद साथी के साथ व्यवसाय।',
        score: 60,
      ),
      RiskOption(
        labelEn: 'My own business, run all by myself.',
        labelHi: 'अपना खुद का व्यवसाय, अकेले चलाना।',
        score: 80,
      ),
    ],
  ),
  RiskQuestion(
    id: 'q4_risk_exposure',
    promptEn: 'How much of your money would you risk to earn higher returns?',
    promptHi: 'अधिक रिटर्न कमाने के लिए आप अपने पैसे का कितना हिस्सा जोखिम में डालेंगे?',
    options: [
      RiskOption(labelEn: 'None of it.', labelHi: 'बिल्कुल नहीं।', score: 20),
      RiskOption(labelEn: 'About 20% of it.', labelHi: 'लगभग 20% हिस्सा।', score: 40),
      RiskOption(labelEn: 'About 40% of it.', labelHi: 'लगभग 40% हिस्सा।', score: 60),
      RiskOption(labelEn: 'More than half of it.', labelHi: 'आधे से ज़्यादा हिस्सा।', score: 80),
    ],
  ),
  RiskQuestion(
    id: 'q5_underperformance_reaction',
    promptEn: 'Your investments are doing badly right now. How do you feel?',
    promptHi: 'अभी आपके निवेश अच्छा प्रदर्शन नहीं कर रहे हैं। आप कैसा महसूस करते हैं?',
    options: [
      RiskOption(
        labelEn: 'Very upset and worried.',
        labelHi: 'बहुत परेशान और चिंतित।',
        score: 20,
      ),
      RiskOption(
        labelEn: 'Worried, but hoping things get better.',
        labelHi: 'चिंतित, पर उम्मीद है हालात सुधरेंगे।',
        score: 40,
      ),
      RiskOption(
        labelEn: 'A little worried, but I can handle it.',
        labelHi: 'थोड़ा चिंतित, पर मैं सह सकता हूँ।',
        score: 60,
      ),
      RiskOption(
        labelEn: 'Not worried — every investment has some risk.',
        labelHi: 'चिंतित नहीं — हर निवेश में कुछ जोखिम होता है।',
        score: 80,
      ),
    ],
  ),
  RiskQuestion(
    id: 'q6_second_chance',
    promptEn: 'Would you invest again in a company where you lost money before?',
    promptHi: 'क्या आप फिर से उस कंपनी में निवेश करेंगे जहाँ पहले आपको नुकसान हुआ था?',
    options: [
      RiskOption(labelEn: 'No way.', labelHi: 'बिल्कुल नहीं।', score: 20),
      RiskOption(
        labelEn: 'Only after thinking about it a lot.',
        labelHi: 'बहुत सोचने के बाद ही।',
        score: 40,
      ),
      RiskOption(
        labelEn: 'Yes, if the company has improved.',
        labelHi: 'हाँ, अगर कंपनी में सुधार हुआ है।',
        score: 60,
      ),
      RiskOption(
        labelEn: 'Yes, past losses don\'t scare me.',
        labelHi: 'हाँ, पुराने नुकसान से मुझे डर नहीं लगता।',
        score: 80,
      ),
    ],
  ),
];

// ─── Phase 2: Demographic Fields ─────────────────────────────────────────

enum DemographicFieldId {
  gender,
  ageGroup,
  income,
  workType,
  education,
  investingExperience,
  investmentDuration,
}

class DemographicField {
  const DemographicField({
    required this.id,
    required this.promptEn,
    required this.promptHi,
    required this.options,
  });
  final DemographicFieldId id;
  final String promptEn;
  final String promptHi;
  final List<DemographicOption> options;

  String prompt(RiskLocale loc) => loc == RiskLocale.hi ? promptHi : promptEn;
}

class DemographicOption {
  const DemographicOption({
    required this.value, // stable string id, persisted to DB
    required this.labelEn,
    required this.labelHi,
    required this.adjustment,
  });
  final String value;
  final String labelEn;
  final String labelHi;
  final int adjustment; // points added to Phase 1 total

  String label(RiskLocale loc) => loc == RiskLocale.hi ? labelHi : labelEn;
}

const demographicFields = <DemographicField>[
  DemographicField(
    id: DemographicFieldId.gender,
    promptEn: 'Gender',
    promptHi: 'लिंग',
    options: [
      DemographicOption(value: 'male',   labelEn: 'Male',   labelHi: 'पुरुष', adjustment: 0),
      DemographicOption(value: 'female', labelEn: 'Female', labelHi: 'महिला', adjustment: 0),
      DemographicOption(value: 'other',  labelEn: 'Other',  labelHi: 'अन्य',  adjustment: 0),
    ],
  ),
  DemographicField(
    id: DemographicFieldId.ageGroup,
    promptEn: 'Age group',
    promptHi: 'आयु वर्ग',
    options: [
      DemographicOption(value: 'under60', labelEn: 'Under 60', labelHi: '60 से कम', adjustment: 20),
      DemographicOption(value: '60plus',  labelEn: '60 and above', labelHi: '60 या अधिक', adjustment: -20),
    ],
  ),
  // Income options shown depend on ageGroup — handled in the screen.
  // Under 60: incomeHigh = ≥ 1 Cr, incomeLow = < 1 Cr
  // 60+:      incomeHigh = ≥ 10 L, incomeLow = < 10 L
  DemographicField(
    id: DemographicFieldId.income,
    promptEn: 'Annual household income',
    promptHi: 'वार्षिक घरेलू आय',
    options: [
      DemographicOption(
        value: 'income_under_1cr',
        labelEn: 'Under ₹1 Crore',
        labelHi: '₹1 करोड़ से कम',
        adjustment: -10,
      ),
      DemographicOption(
        value: 'income_1cr_plus',
        labelEn: '₹1 Crore or more',
        labelHi: '₹1 करोड़ या अधिक',
        adjustment: 15,
      ),
      DemographicOption(
        value: 'income_under_10l',
        labelEn: 'Under ₹10 Lakh',
        labelHi: '₹10 लाख से कम',
        adjustment: -10,
      ),
      DemographicOption(
        value: 'income_10l_plus',
        labelEn: '₹10 Lakh or more',
        labelHi: '₹10 लाख या अधिक',
        adjustment: 15,
      ),
    ],
  ),
  DemographicField(
    id: DemographicFieldId.workType,
    promptEn: 'Work type',
    promptHi: 'कार्य का प्रकार',
    options: [
      DemographicOption(value: 'salaried',     labelEn: 'Salaried',     labelHi: 'वेतनभोगी',      adjustment: 0),
      DemographicOption(value: 'selfEmployed', labelEn: 'Self-employed', labelHi: 'स्वरोजगार', adjustment: 15),
    ],
  ),
  DemographicField(
    id: DemographicFieldId.education,
    promptEn: 'Highest education',
    promptHi: 'उच्चतम शिक्षा',
    options: [
      DemographicOption(
        value: 'graduatePlus',
        labelEn: 'Graduate or higher',
        labelHi: 'स्नातक या अधिक',
        adjustment: 10,
      ),
      DemographicOption(
        value: 'nonGraduate',
        labelEn: 'Not a graduate',
        labelHi: 'स्नातक नहीं',
        adjustment: -5,
      ),
    ],
  ),
  DemographicField(
    id: DemographicFieldId.investingExperience,
    promptEn: 'Years of investing experience',
    promptHi: 'निवेश का अनुभव',
    options: [
      DemographicOption(
        value: 'exp_under_3',
        labelEn: 'Less than 3 years',
        labelHi: '3 साल से कम',
        adjustment: -10,
      ),
      DemographicOption(
        value: 'exp_3_plus',
        labelEn: '3 years or more',
        labelHi: '3 साल या अधिक',
        adjustment: 15,
      ),
    ],
  ),
  DemographicField(
    id: DemographicFieldId.investmentDuration,
    promptEn: 'How long do you plan to stay invested?',
    promptHi: 'आप कितने समय तक निवेशित रहने की योजना बनाते हैं?',
    options: [
      DemographicOption(
        value: 'dur_under_3',
        labelEn: 'Less than 3 years',
        labelHi: '3 साल से कम',
        adjustment: -15,
      ),
      DemographicOption(
        value: 'dur_3_plus',
        labelEn: '3 years or more',
        labelHi: '3 साल या अधिक',
        adjustment: 25,
      ),
    ],
  ),
];

/// Returns the income option subset appropriate for the given age group.
List<DemographicOption> incomeOptionsFor(String ageGroupValue) {
  final all = demographicFields
      .firstWhere((f) => f.id == DemographicFieldId.income)
      .options;
  if (ageGroupValue == '60plus') {
    return all.where((o) => o.value.contains('10l')).toList();
  }
  return all.where((o) => o.value.contains('1cr')).toList();
}

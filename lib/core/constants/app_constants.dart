/// Central configuration constants — never hardcode these elsewhere
abstract class AppConstants {
  // ─── Supabase ─────────────────────────────────────────────────────────────
  // Injected via --dart-define at build time; read from environment
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // ─── Firebase ─────────────────────────────────────────────────────────────
  static const String firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const String firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
  static const String firebaseVapidKey =
      String.fromEnvironment('FIREBASE_VAPID_KEY', defaultValue: '');

  // ─── App info ─────────────────────────────────────────────────────────────
  static const String appName = 'eVesh';
  static const String appVersion = '1.0.0';
  static const String appEnv =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static bool get isProduction => appEnv == 'production';

  // ─── External APIs ────────────────────────────────────────────────────────
  static const String mfCaptnemoBaseUrl = 'https://mf.captnemo.in';
  static const String mfApiBaseUrl = 'https://api.mfapi.in/mf';
  static const String amfiNavAllUrl =
      'https://portal.amfiindia.com/spages/NAVAll.txt';
  static const String kuveraApiBaseUrl = 'https://api.kuvera.in/mf/api/v4';

  // ─── Subscription tier limits ─────────────────────────────────────────────
  static const int freeTierMaxTransactions = 50;
  static const int freeTierMaxMembers = 1;       // 1 self
  static const int individualTierMaxMembers = 1;  // 1 self

  // ─── Default financial parameters ────────────────────────────────────────
  static const double defaultRiskFreeRate = 0.065;     // 6.5% G-Sec yield
  static const double defaultInflationRate = 0.06;     // 6% inflation assumption
  static const double rebalanceDriftThreshold = 5.0;   // 5% drift triggers rebalance

  // ─── Tax rules FY 2025-26 (post July 2024 Budget) ─────────────────────────
  static const double equityLtcgRate = 0.125;          // 12.5%
  static const double equityStcgRate = 0.20;           // 20%
  static const double debtTaxRate = 0.0;               // Slab rate (computed separately)
  static const double ltcgExemptionPerPersonPerFy = 125000.0; // Rs 1,25,000
  static const int equityLtcgHoldingDays = 365;        // >12 months = LTCG for equity
  static const int debtLtcgHoldingDays = 1095;         // >36 months = LTCG for debt (pre-Apr 2023)
  static const int goldFofLtcgHoldingDays = 730;       // >24 months = LTCG for Gold/FoF (post Budget 2024)
  static const double goldFofLtcgRate = 0.125;         // 12.5% LTCG for Gold/FoF
  static const double goldFofStcgRate = 0.20;          // Slab rate (but capped in practice)
  static const double healthEducationCess = 0.04;      // 4% cess

  // ─── Grandfathering (equity bought before Feb 1, 2018) ────────────────────
  /// Equity LTCG gains before this date are grandfathered.
  /// adjustedCost = max(actualCost, min(jan31Nav, saleNav))
  static final DateTime grandfatheringCutoff = DateTime(2018, 2, 1);

  // ─── Debt taxation cutoff (post Apr 1, 2023 = slab rate always) ──────────
  /// Debt MFs purchased on/after this date: always slab rate, no LTCG benefit.
  /// Debt MFs purchased before: 20% with indexation if held > 36 months.
  static final DateTime debtSlabCutoff = DateTime(2023, 4, 1);

  // ─── 3-Bucket framework ───────────────────────────────────────────────────
  static const String bucket1Name = 'Stability';       // 0–3 year horizon
  static const String bucket2Name = 'Income';          // 3–7 year horizon
  static const String bucket3Name = 'Growth';          // 7+ year horizon

  // ─── Alert thresholds (defaults) ─────────────────────────────────────────
  static const double navDropAlertThresholdPct = 3.0;  // alert if NAV drops > 3%
  static const int sipReminderDaysBefore = 3;           // alert 3 days before SIP
  static const int maturityAlertUrgentDays = 7;         // URGENT if ≤ 7 days
  static const int maturityAlertMediumDays = 30;        // MEDIUM if ≤ 30 days
  static const double xirrBelowTargetThreshold = 8.0;  // alert if XIRR drops < 8%

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int transactionsPageSize = 50;
  static const int fundSearchMaxResults = 20;

  // ─── Local storage Hive box names ─────────────────────────────────────────
  static const String hiveBoxNavCache = 'nav_cache';
  static const String hiveBoxFundList = 'fund_list';
  static const String hiveBoxPortfolioSnapshot = 'portfolio_snapshot';
  static const String hiveBoxPendingTransactions = 'pending_transactions';
  static const String hiveBoxUserPrefs = 'user_prefs';

  // ─── NAV display formats ──────────────────────────────────────────────────
  static const String navDateFormat = 'dd-MM-yyyy';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayMonthYearFormat = 'MMM yyyy';

  // ─── Indian financial year ────────────────────────────────────────────────
  // FY starts April 1; e.g., FY2526 = April 1, 2025 – March 31, 2026
  static const int fyStartMonth = 4;   // April
  static const int fyStartDay = 1;

  // ─── Market intel defaults ─────────────────────────────────────────────────
  static const double niftyPeOvervalued = 25.0;    // P/E > 25 = overvalued signal
  static const double niftyPeUndervalued = 16.0;   // P/E < 16 = cheap signal
  static const double vixHighFear = 25.0;           // VIX > 25 = high fear
  static const double vixLowFear = 13.0;            // VIX < 13 = complacency
  static const double gsecYieldHigh = 7.5;          // G-Sec > 7.5% favours debt
}

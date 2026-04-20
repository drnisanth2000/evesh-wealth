/// Named route constants — use these everywhere instead of hard-coded strings
abstract class Routes {
  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String mfaSetup = '/auth/mfa-setup';
  static const String mfaChallenge = '/auth/mfa-challenge';
  static const String emailConfirm = '/auth/confirm';
  static const String onboarding = '/onboarding';

  // Main shell
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String uploadMfCentral = '/transactions/upload';
  static const String fundMaster = '/portfolio';
  static const String fundDetail = '/portfolio/:amfiCode';
  static const String analytics = '/analytics';
  static const String tax = '/tax';
  static const String uploadTax = '/tax/upload';
  static const String rebalance = '/rebalance';
  static const String goals = '/goals';
  static const String whatIf = '/what-if';
  static const String suggestions = '/suggestions';
  static const String otherAssets = '/other-assets';
  static const String marketIntel = '/market-intel';

  // Wealth Planner v2 — shell + top-tab deep links
  static const String wealthPlanner = '/wealth-planner';
  // `/wealth-planner/mf` retired — router now redirects to /allocation.
  static const String wealthPlannerGoals = '/wealth-planner/goals';
  static const String wealthPlannerAllocation = '/wealth-planner/allocation';
  static const String wealthPlannerRebalance = '/wealth-planner/rebalance';
  static const String wealthPlannerLegacy = '/wealth-planner/legacy';
  // Pre-v2 sub-screens (kept alive while we migrate)
  static const wealthPlannerRetirement = '/wealth-planner/retirement';
  static const String wealthPlannerWizard = '/wealth-planner/wizard';
  static const String wealthPlannerWatchlist = '/wealth-planner/watchlist';
  static const String wealthPlannerProjections = '/wealth-planner/projections';
  static const String wealthPlannerActions = '/wealth-planner/actions';

  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String mfaEnroll = '/settings/mfa';
  static const String subscription = '/settings/subscription';

  // Family setup
  static const String familySetup = '/settings/family';

  // Risk profiling
  static const String riskProfile = '/risk-profile';
  static const String riskQuestionnaire = '/risk-profile/quiz';

  // Goal landing (stub — full flow in next plan)
  static const String goalLanding = '/goal-landing';

  // Data management
  static const String dataAudit = '/settings/data-audit';
  static const String dataWipe = '/settings/data-wipe';

  // Notification preferences
  static const String notificationPrefs = '/settings/notification-prefs';

  // Admin
  static const String admin = '/admin';
  static const String adminUsers = '/admin/users';
}

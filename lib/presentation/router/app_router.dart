import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/auth_provider.dart';
import '../providers/family_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/mfa_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_host_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/upload_mfcentral_screen.dart';
import '../../data/models/transaction_model.dart';
import '../screens/fund_master/fund_master_screen.dart';
import '../screens/fund_master/fund_detail_screen.dart';
import '../screens/tax/tax_screen.dart';
import '../screens/tax/upload_tax_screen.dart';
import '../screens/rebalance/rebalance_screen.dart';
import '../screens/what_if/what_if_screen.dart';
import '../screens/suggestions/suggestions_screen.dart';
import '../screens/other_assets/other_assets_screen.dart';
import '../screens/market_intel/mf_screener_screen.dart';
import '../screens/wealth_planner/wealth_planner_dashboard_screen.dart';
import '../screens/wealth_planner/wealth_planner_shell.dart';
import '../screens/wealth_planner/retirement_detail_screen.dart';
import '../screens/wealth_planner/projection_screen.dart';
import '../screens/wealth_planner/action_center_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import '../screens/watchlist/add_rule_screen.dart';
import '../../data/models/watchlist_rule_model.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../screens/settings/family_setup_screen.dart';
import '../screens/settings/subscription_screen.dart';
import '../screens/settings/data_audit_screen.dart';
import '../screens/settings/data_wipe_screen.dart';
import '../screens/settings/notification_prefs_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/risk_profile/risk_profile_screen.dart';
import '../screens/risk_profile/risk_questionnaire_screen.dart';
import '../screens/goals/goal_landing_screen.dart';
import '../widgets/common/main_shell.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  // Watch only session presence so token-refresh events don't rebuild the
  // entire router (which would reset navigation to initialLocation).
  final isLoggedIn = ref.watch(
    authStateProvider.select((s) => s.valueOrNull?.session != null),
  );

  return GoRouter(
    initialLocation: Routes.login,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return Routes.login;
      if (isLoggedIn && isAuthRoute) return Routes.dashboard;

      // Admin guard: if the profile is already loaded and the user is not
      // an admin, bounce them to dashboard instead of rendering the screen
      // (which would otherwise show the deny state). If the profile is not
      // yet resolved, the AdminScreen itself shows a spinner and handles it.
      if (state.matchedLocation == Routes.admin) {
        final profile = ref.read(currentProfileProvider).valueOrNull;
        if (profile != null && !profile.isAdmin) {
          return Routes.dashboard;
        }
      }

      return null;
    },
    routes: [
      // ── Auth routes (no shell) ────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        builder: (ctx, _) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (ctx, _) => const SignupScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (ctx, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.mfaChallenge,
        builder: (ctx, _) => const MfaScreen(mode: MfaMode.challenge),
      ),
      GoRoute(
        path: Routes.mfaSetup,
        builder: (ctx, _) => const MfaScreen(mode: MfaMode.setup),
      ),

      // ── Main app shell (persistent bottom nav) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (ctx, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.transactions,
            builder: (ctx, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return TransactionsHostScreen(
                initialSearch: extra?['search'] as String?,
              );
            },
            routes: [
              GoRoute(
                path: 'add',
                builder: (ctx, state) => AddTransactionScreen(
                  editTransaction: state.extra as TransactionModel?,
                ),
              ),
              GoRoute(
                path: 'upload',
                builder: (ctx, _) => const UploadMfCentralScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.fundMaster,
            builder: (ctx, _) => const FundMasterScreen(),
            routes: [
              GoRoute(
                path: ':amfiCode',
                builder: (ctx, state) => FundDetailScreen(
                  amfiCode: int.parse(state.pathParameters['amfiCode']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.analytics,
            builder: (ctx, _) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: Routes.tax,
            builder: (ctx, _) => const TaxScreen(),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (ctx, _) => const UploadTaxScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.rebalance,
            builder: (ctx, _) => const RebalanceScreen(),
          ),
          GoRoute(
            path: Routes.goals,
            // Canonical Goals page — term cards + per-goal progress + fund
            // chips. `/goal-landing` below is kept as a redirect alias until
            // every caller migrates to `/goals`.
            builder: (ctx, _) => const GoalLandingScreen(),
          ),
          GoRoute(
            path: Routes.whatIf,
            builder: (ctx, _) => const WhatIfScreen(),
          ),
          GoRoute(
            path: Routes.suggestions,
            builder: (ctx, _) => const SuggestionsScreen(),
          ),
          GoRoute(
            path: Routes.otherAssets,
            builder: (ctx, _) => const OtherAssetsScreen(),
          ),
          GoRoute(
            path: Routes.marketIntel,
            builder: (ctx, _) => const MFScreenerScreen(),
          ),
          GoRoute(
            path: Routes.wealthPlanner,
            builder: (ctx, _) => const WealthPlannerShell(),
            routes: [
              // v2 sub-tab deep links — open the shell on a specific top tab.
              // Tab order: 0=Goals, 1=Allocation, 2=Rebalance (My MF retired).
              GoRoute(
                path: 'goals',
                builder: (ctx, _) => const WealthPlannerShell(initialTab: 0),
              ),
              GoRoute(
                path: 'allocation',
                builder: (ctx, _) => const WealthPlannerShell(initialTab: 1),
              ),
              GoRoute(
                path: 'rebalance',
                builder: (ctx, _) => const WealthPlannerShell(initialTab: 2),
              ),
              // `/wealth-planner/mf` is retired — any surviving caller lands
              // on Allocation (the new home for fund holdings).
              GoRoute(
                path: 'mf',
                redirect: (ctx, state) => '/wealth-planner/allocation',
              ),
              // Pre-v2 dashboard, kept for one release as a safety net.
              GoRoute(
                path: 'legacy',
                builder: (ctx, _) => const WealthPlannerDashboardScreen(),
              ),
              GoRoute(
                path: 'retirement',
                builder: (ctx, _) => const RetirementDetailScreen(),
              ),
              GoRoute(
                path: 'projections',
                builder: (ctx, _) => const ProjectionScreen(),
              ),
              GoRoute(
                path: 'actions',
                builder: (ctx, _) => const ActionCenterScreen(),
              ),
              GoRoute(
                path: 'watchlist',
                builder: (ctx, _) => const WatchlistScreen(),
              ),
              GoRoute(
                path: 'watchlist/add',
                builder: (ctx, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return AddRuleScreen(
                    initialAmfiCode: extra?['amfiCode'] as int?,
                    initialFundName: extra?['fundName'] as String?,
                    editRule: extra?['editRule'] as WatchlistRuleModel?,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.alerts,
            builder: (ctx, _) => const AlertsScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            builder: (ctx, _) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'profile',
                builder: (ctx, _) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'mfa',
                builder: (ctx, _) => const MfaScreen(mode: MfaMode.setup),
              ),
              GoRoute(
                path: 'family',
                builder: (ctx, _) => const FamilySetupScreen(),
              ),
              GoRoute(
                path: 'subscription',
                builder: (ctx, _) => const SubscriptionScreen(),
              ),
              GoRoute(
                path: 'data-audit',
                builder: (ctx, _) => const DataAuditScreen(),
              ),
              GoRoute(
                path: 'data-wipe',
                builder: (ctx, _) => const DataWipeScreen(),
              ),
              GoRoute(
                path: 'notification-prefs',
                builder: (ctx, _) => const NotificationPrefsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.admin,
            builder: (ctx, _) => const AdminScreen(),
          ),
          GoRoute(
            path: Routes.riskProfile,
            builder: (ctx, _) => const RiskProfileScreen(),
            routes: [
              GoRoute(
                path: 'quiz',
                builder: (ctx, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return RiskQuestionnaireScreen(
                    memberId: extra?['memberId'] as String?,
                  );
                },
              ),
            ],
          ),
          // Legacy alias — redirect to the canonical Goals route. Callers
          // using `Routes.goalLanding` (e.g. settings > family > goals) keep
          // working; new code should use `Routes.goals`.
          GoRoute(
            path: Routes.goalLanding,
            redirect: (_, __) => Routes.goals,
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}


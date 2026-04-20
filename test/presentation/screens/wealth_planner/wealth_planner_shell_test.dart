import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/family_model.dart';
import 'package:evesh_wealth/domain/usecases/run_rebalance_analysis.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:evesh_wealth/presentation/providers/family_provider.dart';
import 'package:evesh_wealth/presentation/providers/goal_provider.dart';
import 'package:evesh_wealth/presentation/providers/rebalance_dismissal_provider.dart';
import 'package:evesh_wealth/presentation/providers/rebalance_provider.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/wealth_planner_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

// MemberSelector returns SizedBox.shrink() when the family list is empty, so
// the "All" chip is only rendered when at least one member is provided.
const _testMember = FamilyMemberModel(
  id: 'member-1',
  familyId: 'family-1',
  ownerId: 'owner-1',
  displayName: 'Test Member',
);

BucketCompositionResult _emptyBuckets() {
  return BucketCompositionResult(
    buckets: List.unmodifiable([
      for (final b in Bucket.values)
        BucketComposition(
          bucket: b,
          currentValue: 0,
          currentPct: 0,
          targetPct: 0,
          gapPct: 0,
          gapRupees: 0,
          funds: const [],
          otherAssets: const [],
          goalAlerts: const [],
        ),
    ]),
    totalValue: 0,
  );
}

Widget _wrap({int initialTab = 0}) {
  return ProviderScope(
    overrides: [
      familyMembersProvider.overrideWith((ref) async => [_testMember]),
      bucketCompositionProvider(null)
          .overrideWith((ref) async => _emptyBuckets()),
      rebalanceAnalysisProvider(null).overrideWith(
        (ref) async => const RebalanceResult(
          totalPortfolioValue: 0,
          allocationDrifts: [],
          bucketAllocations: [],
          topFundSuggestions: [],
          rebalanceNeeded: false,
          driftThreshold: 5,
        ),
      ),
      rebalanceDismissalsProvider(null).overrideWith((ref) async => const []),
      goalsProvider.overrideWith((ref) async => const []),
      goalFundLinksProvider.overrideWith((ref) async => const []),
    ],
    child: MaterialApp(
      home: WealthPlannerShell(initialTab: initialTab),
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp
        .createTemp('evesh_wealth_planner_shell_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxUserPrefs);
  });

  tearDown(() async {
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WealthPlannerShell', () {
    testWidgets('renders with title "Wealth Planner"', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Wealth Planner'), findsOneWidget);
    });

    testWidgets('has the 3 top-level tab labels (My MF retired)',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Goals'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Asset Allocation'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Rebalance'), findsOneWidget);
      // Ensure the retired My MF tab isn't revived.
      expect(find.widgetWithText(Tab, 'My Mutual Funds'), findsNothing);
    });

    testWidgets('initialTab: 1 opens with Asset Allocation selected',
        (tester) async {
      await tester.pumpWidget(_wrap(initialTab: 1));
      await tester.pumpAndSettle();

      // Allocation sub-tabs are Fund (default) and Bucket.
      expect(find.widgetWithText(Tab, 'Fund'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Bucket'), findsOneWidget);
    });

    testWidgets('tapping a top tab swaps the visible body', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Default tab is Asset Allocation (initialTab = 1). Switch to
      // Rebalance to verify TabBarView children are live.
      await tester.tap(find.widgetWithText(Tab, 'Rebalance'));
      await tester.pumpAndSettle();

      // Asset Allocation sub-tabs disappear when we're on Rebalance.
      expect(find.widgetWithText(Tab, 'Fund'), findsNothing);
    });

    testWidgets('GlobalMemberHeader renders with "All" chip visible',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
    });
  });
}

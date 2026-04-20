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

Widget _wrap() {
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
    child: const MaterialApp(
      home: WealthPlannerShell(initialTab: 3),
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp
        .createTemp('evesh_rebalance_tab_smoke_test_');
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

  group('RebalanceTab smoke', () {
    testWidgets('renders 2 inner sub-tab labels', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Tab, 'Actions'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Dismissed'), findsOneWidget);
      // Buckets no longer lives under Rebalance — moved to Allocation > Bucket.
      expect(find.widgetWithText(Tab, 'Buckets'), findsNothing);
    });

    testWidgets('Actions empty-state shows when no reallocation needed',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No reallocation needed'),
        findsOneWidget,
      );
    });

    testWidgets('Dismissed empty-state appears when no dismissals',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Dismissed'));
      await tester.pumpAndSettle();

      expect(find.text('No dismissed suggestions'), findsOneWidget);
    });
  });
}

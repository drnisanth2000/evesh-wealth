import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/data/models/portfolio_summary_model.dart';
import 'package:evesh_wealth/domain/usecases/run_rebalance_analysis.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:evesh_wealth/presentation/providers/pending_moves_provider.dart';
import 'package:evesh_wealth/presentation/providers/rebalance_dismissal_provider.dart';
import 'package:evesh_wealth/presentation/providers/rebalance_provider.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/sub/rebal_actions_tab.dart';
import 'package:evesh_wealth/presentation/widgets/common/fund_search_dropdown.dart';
import 'package:evesh_wealth/presentation/widgets/wealth_planner/move_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

BucketCompositionResult _compositionWithOnlyGrowth() {
  const growthLine = HoldingLine(
    holding: FundHoldingSummary(
      amfiCode: 1,
      fundName: 'Growth Fund',
      category: 'core equity',
      taxCategory: 'equity',
      currentValue: 100000,
      totalInvested: 100000,
    ),
    effectiveBucket: Bucket.growth,
    isOverridden: false,
  );
  return BucketCompositionResult(
    buckets: List.unmodifiable([
      const BucketComposition(
        bucket: Bucket.liquid,
        currentValue: 0,
        currentPct: 0,
        targetPct: 20,
        gapPct: -20,
        gapRupees: -20000,
        funds: [],
        otherAssets: [],
        goalAlerts: [],
      ),
      const BucketComposition(
        bucket: Bucket.fixedIncome,
        currentValue: 0,
        currentPct: 0,
        targetPct: 20,
        gapPct: -20,
        gapRupees: -20000,
        funds: [],
        otherAssets: [],
        goalAlerts: [],
      ),
      const BucketComposition(
        bucket: Bucket.growth,
        currentValue: 100000,
        currentPct: 100,
        targetPct: 60,
        gapPct: 40,
        gapRupees: 40000,
        funds: [growthLine],
        otherAssets: [],
        goalAlerts: [],
      ),
    ]),
    totalValue: 100000,
  );
}

Widget _wrapTab(BucketCompositionResult composition) {
  return ProviderScope(
    overrides: [
      bucketCompositionProvider(null)
          .overrideWith((ref) async => composition),
      rebalanceAnalysisProvider(null).overrideWith(
        (ref) async => const RebalanceResult(
          totalPortfolioValue: 100000,
          allocationDrifts: [],
          bucketAllocations: [],
          topFundSuggestions: [],
          rebalanceNeeded: false,
          driftThreshold: 5,
        ),
      ),
      rebalanceDismissalsProvider(null).overrideWith((ref) async => const []),
    ],
    child: const MaterialApp(
      home: Scaffold(body: RebalActionsTab()),
    ),
  );
}

Widget _wrapMoveCard({
  required List<FundHoldingSummary> destinationOptions,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: MoveCard(
          id: 'test-move',
          kind: PendingMoveKind.deployment,
          fromBucket: Bucket.liquid,
          fromAmfi: null,
          fromFundName: 'Fresh capital',
          toBucket: Bucket.liquid,
          initialToAmfi: null,
          initialToFundName: null,
          initialAmount: 50000,
          destinationOptions: destinationOptions,
          reason: 'Liquid underweight',
          onSave: () {},
          onDismiss: () {},
          onExecute: (_, __, ___) {},
        ),
      ),
    ),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir =
        await Directory.systemTemp.createTemp('evesh_rebal_actions_tab_test_');
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

  group('RebalActionsTab', () {
    testWidgets(
      'Compute with ₹1L lumpsum + only-Growth composition emits MoveCards '
      'including at least one with empty destinationOptions (empty bucket)',
      (tester) async {
        await tester.pumpWidget(_wrapTab(_compositionWithOnlyGrowth()));
        await tester.pumpAndSettle();

        final lumpsumField = find
            .byWidgetPredicate((w) =>
                w is TextField &&
                w.decoration?.labelText == 'Lumpsum (₹)')
            .first;
        await tester.enterText(lumpsumField, '100000');
        await tester.tap(find.text('Compute'));
        await tester.pumpAndSettle();

        final moveCards = tester.widgetList<MoveCard>(find.byType(MoveCard));
        expect(moveCards, isNotEmpty);
        final empties =
            moveCards.where((m) => m.destinationOptions.isEmpty).toList();
        expect(
          empties,
          isNotEmpty,
          reason:
              'Expected at least one MoveCard routing into an empty bucket',
        );
      },
    );
  });

  group('MoveCard inline fund search', () {
    testWidgets(
      'empty destinationOptions → expanded body renders FundSearchDropdown inline',
      (tester) async {
        await tester.pumpWidget(_wrapMoveCard(destinationOptions: const []));
        await tester.pumpAndSettle();

        // Expand the card by tapping on its header InkWell.
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(find.byType(FundSearchDropdown), findsOneWidget);
      },
    );

    testWidgets(
      'non-empty destinationOptions → expanded body renders Dropdown, no inline search',
      (tester) async {
        const holding = FundHoldingSummary(
          amfiCode: 42,
          fundName: 'Existing Debt Fund',
          category: 'debt',
          taxCategory: 'debt',
          currentValue: 50000,
          totalInvested: 50000,
        );
        await tester
            .pumpWidget(_wrapMoveCard(destinationOptions: [holding]));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(find.byType(FundSearchDropdown), findsNothing);
        expect(find.byType(DropdownButton<int>), findsOneWidget);
      },
    );

    testWidgets(
      'concentration warning appears when post-move destination share > limit',
      (tester) async {
        // Destination fund is the ONLY fund in the bucket. Any incoming
        // amount makes it 100% of the bucket → warning must render.
        const holding = FundHoldingSummary(
          amfiCode: 42,
          fundName: 'Sole Growth Fund',
          category: 'core equity',
          taxCategory: 'equity',
          currentValue: 100000,
          totalInvested: 100000,
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MoveCard(
                  id: 'conc-test',
                  kind: PendingMoveKind.reallocation,
                  fromBucket: Bucket.liquid,
                  fromAmfi: 7,
                  fromFundName: 'Some Liquid',
                  toBucket: Bucket.growth,
                  initialToAmfi: 42,
                  initialToFundName: 'Sole Growth Fund',
                  initialAmount: 50000,
                  destinationOptions: const [holding],
                  toBucketCurrentValue: 100000,
                  concentrationLimitPct: 35,
                  reason: 'test',
                  onSave: () {},
                  onDismiss: () {},
                  onExecute: (_, __, ___) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Expand the card.
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Concentration'), findsOneWidget);
        // 150k / 150k = 100% which exceeds 35 cap → message mentions 100%.
        expect(find.textContaining('100%'), findsOneWidget);
      },
    );

    testWidgets(
      'no concentration warning when destination stays within limit',
      (tester) async {
        // Bucket already has plenty of diversified value so a small inbound
        // doesn't push any single fund over 35%.
        final holdings = [
          const FundHoldingSummary(
            amfiCode: 42,
            fundName: 'Fund A',
            category: 'core equity',
            taxCategory: 'equity',
            currentValue: 300000,
            totalInvested: 300000,
          ),
          const FundHoldingSummary(
            amfiCode: 43,
            fundName: 'Fund B',
            category: 'core equity',
            taxCategory: 'equity',
            currentValue: 300000,
            totalInvested: 300000,
          ),
          const FundHoldingSummary(
            amfiCode: 44,
            fundName: 'Fund C',
            category: 'core equity',
            taxCategory: 'equity',
            currentValue: 400000,
            totalInvested: 400000,
          ),
        ];
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: MoveCard(
                  id: 'ok-test',
                  kind: PendingMoveKind.reallocation,
                  fromBucket: Bucket.liquid,
                  fromAmfi: 7,
                  fromFundName: 'Some Liquid',
                  toBucket: Bucket.growth,
                  initialToAmfi: 42,
                  initialToFundName: 'Fund A',
                  initialAmount: 20000,
                  destinationOptions: holdings,
                  toBucketCurrentValue: 1000000,
                  concentrationLimitPct: 35,
                  reason: 'test',
                  onSave: () {},
                  onDismiss: () {},
                  onExecute: (_, __, ___) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        // 320k / 1020k ≈ 31.4% → below 35% cap → no warning.
        expect(find.textContaining('Concentration'), findsNothing);
      },
    );
  });
}

import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/core/constants/bucket_mapping.dart';
import 'package:evesh_wealth/domain/models/allocation_models.dart';
import 'package:evesh_wealth/presentation/providers/bucket_composition_provider.dart';
import 'package:evesh_wealth/presentation/providers/selected_member_provider.dart';
import 'package:evesh_wealth/presentation/providers/wealth_planner_provider.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/sub/alloc_bucket_tab.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/tabs/allocation_tab.dart';
import 'package:evesh_wealth/presentation/widgets/wealth_planner/total_allocation_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ─── Fixtures ───────────────────────────────────────────────────────────────

BucketCompositionResult _fixtureResult({
  Map<Bucket, double> currentPct = const {
    Bucket.liquid: 10,
    Bucket.fixedIncome: 30,
    Bucket.growth: 60,
  },
  Map<Bucket, double> targetPct = const {
    Bucket.liquid: 10,
    Bucket.fixedIncome: 30,
    Bucket.growth: 60,
  },
}) {
  final buckets = [
    for (final b in Bucket.values)
      BucketComposition(
        bucket: b,
        currentValue: 0,
        currentPct: currentPct[b] ?? 0,
        targetPct: targetPct[b] ?? 0,
        gapPct: (currentPct[b] ?? 0) - (targetPct[b] ?? 0),
        gapRupees: 0,
        funds: const [],
        otherAssets: const [],
        goalAlerts: const [],
      ),
  ];
  return BucketCompositionResult(
    buckets: List.unmodifiable(buckets),
    totalValue: 0,
  );
}

BucketCompositionResult _zeroResult() => _fixtureResult(
      currentPct: const {},
      targetPct: const {},
    );

// Minimal AllocationHealthResult stub for test fixtures.
AllocationHealthResult _healthStub() => AllocationHealthResult(
      healthScore: 75,
      healthLabel: 'Good',
      idealAllocation: const IdealAllocation(
        riskProfile: 'Moderate',
        age: 35,
        corePct: 0,
        satellitePct: 0,
        subBuckets: [],
      ),
      currentAllocation: const {},
      driftAlerts: const [],
      nudges: const [],
    );

// ─── Test harness ───────────────────────────────────────────────────────────

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

class _StubSelectedMember extends SelectedMember {
  _StubSelectedMember(this._initial);
  final String? _initial;
  @override
  String? build() => _initial;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp
        .createTemp('evesh_allocation_tab_smoke_test_');
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

  group('AllocationTab', () {
    testWidgets('renders 2 inner tab labels (Bucket + Fund)', (tester) async {
      await tester.pumpWidget(_wrap(
        const AllocationTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          bucketCompositionProvider(null)
              .overrideWith((ref) async => _fixtureResult()),
          allocationHealthProvider(null)
              .overrideWith((ref) async => _healthStub()),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bucket'), findsOneWidget);
      expect(find.text('Fund'), findsOneWidget);
      // Asset sub-tab retired — target-setting now lives inside the Fund tab.
      expect(find.widgetWithText(Tab, 'Asset'), findsNothing);
    });

    testWidgets('bucket strip shows all 3 bucket display names',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AllocationTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          bucketCompositionProvider(null)
              .overrideWith((ref) async => _fixtureResult()),
          allocationHealthProvider(null)
              .overrideWith((ref) async => _healthStub()),
        ],
      ));
      await tester.pumpAndSettle();

      // Fund is the default sub-tab after the reorder — tap Bucket first.
      await tester.tap(find.widgetWithText(Tab, 'Bucket'));
      await tester.pumpAndSettle();

      expect(find.text('Liquid'), findsWidgets);
      expect(find.text('Fixed Income'), findsWidgets);
      expect(find.text('Growth'), findsWidgets);
    });
  });

  group('AllocBucketTab', () {
    testWidgets('renders empty state when buckets have zero values',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AllocBucketTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          bucketCompositionProvider(null)
              .overrideWith((ref) async => _zeroResult()),
        ],
      ));
      await tester.pumpAndSettle();

      // Bucket sub-tab now shows a silhouette strip + ONE detail card for
      // the selected bucket (default = Liquid). Empty state appears once.
      expect(find.textContaining('No holdings in this bucket'), findsOneWidget);
    });
  });

  group('TotalAllocationIndicator', () {
    testWidgets('green pill at 100', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TotalAllocationIndicator(total: 100),
        ),
      ));
      await tester.pump();

      expect(find.text('Balanced 100%'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('red pill with delta at 95', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TotalAllocationIndicator(total: 95),
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Total 95.0%'), findsOneWidget);
      expect(find.textContaining('-5.0%'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}

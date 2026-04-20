import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/data/models/family_model.dart';
import 'package:evesh_wealth/data/models/pending_order_model.dart';
import 'package:evesh_wealth/presentation/providers/family_provider.dart';
import 'package:evesh_wealth/presentation/providers/pending_orders_provider.dart';
import 'package:evesh_wealth/presentation/providers/selected_member_provider.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/sub/mf_buy_tab.dart';
import 'package:evesh_wealth/presentation/screens/wealth_planner/sub/mf_order_status_tab.dart';
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

const _sampleOrder = PendingOrderModel(
  id: 'o1',
  ownerId: 'owner-1',
  familyId: 'family-1',
  memberId: 'member-1',
  amfiCode: 12345,
  fundName: 'Parag Parikh Flexi Cap Fund',
  orderKind: 'lumpsum',
  amount: 50000,
  status: 'placed',
  source: 'manual',
  createdAt: '2026-04-18T00:00:00Z',
);

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir =
        await Directory.systemTemp.createTemp('evesh_mf_tabs_smoke_test_');
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

  group('MfBuyTab', () {
    testWidgets('renders screener link and Save button', (tester) async {
      await tester.pumpWidget(_wrap(
        const MfBuyTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          familyMembersProvider.overrideWith((ref) async => [_testMember]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Open Smart Screener'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('MfOrderStatusTab', () {
    testWidgets('renders empty state when no orders', (tester) async {
      await tester.pumpWidget(_wrap(
        const MfOrderStatusTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          pendingOrdersProvider(null).overrideWith((ref) async => const []),
        ],
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No orders yet'),
        findsOneWidget,
      );
    });

    testWidgets('renders a card for a single synthetic order',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const MfOrderStatusTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          pendingOrdersProvider(null)
              .overrideWith((ref) async => const [_sampleOrder]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Parag Parikh Flexi Cap Fund'), findsOneWidget);
    });

    testWidgets('pill filter labels render', (tester) async {
      await tester.pumpWidget(_wrap(
        const MfOrderStatusTab(),
        overrides: [
          selectedMemberProvider.overrideWith(() => _StubSelectedMember(null)),
          pendingOrdersProvider(null).overrideWith((ref) async => const []),
        ],
      ));
      await tester.pumpAndSettle();

      for (final label in const [
        'All',
        'SIP',
        'Buy/Lumpsum',
        'Switch',
        'SWP',
        'Sell',
        'Gift',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing pill: $label');
      }
    });
  });
}

class _StubSelectedMember extends SelectedMember {
  _StubSelectedMember(this._initial);
  final String? _initial;
  @override
  String? build() => _initial;
}

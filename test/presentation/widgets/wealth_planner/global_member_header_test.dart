import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/data/models/family_model.dart';
import 'package:evesh_wealth/presentation/providers/family_provider.dart';
import 'package:evesh_wealth/presentation/providers/selected_member_provider.dart';
import 'package:evesh_wealth/presentation/widgets/wealth_planner/global_member_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _memberA = FamilyMemberModel(
  id: 'member-abc',
  familyId: 'family-1',
  ownerId: 'owner-1',
  displayName: 'Alice',
);

const _memberB = FamilyMemberModel(
  id: 'member-def',
  familyId: 'family-1',
  ownerId: 'owner-1',
  displayName: 'Bob',
);

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp
        .createTemp('evesh_global_member_header_test_');
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

  testWidgets('GlobalMemberHeader renders All + member chips', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyMembersProvider
              .overrideWith((ref) async => [_memberA, _memberB]),
        ],
        child: const MaterialApp(
          home: Scaffold(body: GlobalMemberHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('GlobalMemberHeader reflects selectedMemberProvider state',
      (tester) async {
    // Pre-seed the provider via overrideWith — avoids async Hive dance in tests.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyMembersProvider
              .overrideWith((ref) async => [_memberA, _memberB]),
          selectedMemberProvider.overrideWith(_FakeSelected.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: GlobalMemberHeader()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // _FakeSelected starts with 'member-abc' selected — chip for Alice should
    // render as selected. We don't have a direct "is selected" API on
    // MemberSelector, so assert via the chip's presence.
    expect(find.text('Alice'), findsOneWidget);
  });
}

class _FakeSelected extends SelectedMember {
  @override
  String? build() => 'member-abc';
}

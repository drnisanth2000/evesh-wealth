import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/presentation/providers/selected_member_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use a VM-side temp dir instead of `Hive.initFlutter` — the latter calls
    // path_provider which has no implementation in the flutter_test host.
    tempDir = await Directory.systemTemp
        .createTemp('evesh_selected_member_test_');
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

  group('SelectedMember provider', () {
    test('default state is null when nothing is persisted', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedMemberProvider), isNull);
    });

    test('select(memberId) updates state and persists to Hive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(selectedMemberProvider.notifier)
          .select('member-123');

      expect(container.read(selectedMemberProvider), equals('member-123'));

      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      expect(box.get('selected_member_id'), equals('member-123'));
    });

    test('rebuilt container reads the persisted value via build()', () async {
      final firstContainer = ProviderContainer();
      await firstContainer
          .read(selectedMemberProvider.notifier)
          .select('member-abc');
      firstContainer.dispose();

      final secondContainer = ProviderContainer();
      addTearDown(secondContainer.dispose);

      expect(
        secondContainer.read(selectedMemberProvider),
        equals('member-abc'),
      );
    });

    test('select(null) clears persisted value and sets state to null',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(selectedMemberProvider.notifier)
          .select('member-xyz');
      expect(container.read(selectedMemberProvider), equals('member-xyz'));

      await container.read(selectedMemberProvider.notifier).select(null);

      expect(container.read(selectedMemberProvider), isNull);
      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      expect(box.containsKey('selected_member_id'), isFalse);
    });
  });
}

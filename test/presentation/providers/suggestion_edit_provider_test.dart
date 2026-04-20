import 'dart:io';

import 'package:evesh_wealth/core/constants/app_constants.dart';
import 'package:evesh_wealth/presentation/providers/suggestion_edit_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp
        .createTemp('evesh_suggestion_edit_test_');
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

  group('SuggestionEdits provider', () {
    test('save(hash, edit) writes to Hive AND state[hash] reflects edit',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const edit = SuggestionEdit(
          toAmfi: 12345, toName: 'Foo Fund', amount: 25000.0);
      await container
          .read(suggestionEditsProvider.notifier)
          .save('hash-1', edit);

      final state = container.read(suggestionEditsProvider);
      expect(state['hash-1']?.toAmfi, equals(12345));
      expect(state['hash-1']?.toName, equals('Foo Fund'));
      expect(state['hash-1']?.amount, equals(25000.0));

      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      final raw = box.get('suggest_edit/hash-1');
      expect(raw, isA<Map>());
      expect((raw as Map)['toAmfi'], equals(12345));
      expect(raw['amount'], equals(25000.0));
    });

    test('after re-creating the container, build() hydrates persisted edits',
        () async {
      final first = ProviderContainer();
      await first.read(suggestionEditsProvider.notifier).save(
          'hash-2', const SuggestionEdit(toAmfi: 999, amount: 7500.0));
      first.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);

      final state = second.read(suggestionEditsProvider);
      expect(state.containsKey('hash-2'), isTrue);
      expect(state['hash-2']?.toAmfi, equals(999));
      expect(state['hash-2']?.amount, equals(7500.0));
    });

    test('clear(hash) removes both Hive entry and state entry', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(suggestionEditsProvider.notifier).save(
          'hash-3', const SuggestionEdit(toAmfi: 1, amount: 1.0));
      expect(
          container.read(suggestionEditsProvider).containsKey('hash-3'), isTrue);

      await container
          .read(suggestionEditsProvider.notifier)
          .clear('hash-3');

      expect(
          container.read(suggestionEditsProvider).containsKey('hash-3'), isFalse);
      final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
      expect(box.containsKey('suggest_edit/hash-3'), isFalse);
    });
  });
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';

part 'suggestion_edit_provider.g.dart';

/// Per-suggestion local edits (destination amfi + amount). Keyed by
/// suggestion hash. Persists across reloads in the `user_prefs` Hive box
/// under prefix `suggest_edit/`.
class SuggestionEdit {
  final int? toAmfi; // null = sell-to-bank / no destination chosen
  final String? toName;
  final double? amount;
  const SuggestionEdit({this.toAmfi, this.toName, this.amount});

  Map<String, dynamic> toJson() => {
        if (toAmfi != null) 'toAmfi': toAmfi,
        if (toName != null) 'toName': toName,
        if (amount != null) 'amount': amount,
      };

  factory SuggestionEdit.fromJson(Map m) => SuggestionEdit(
        toAmfi: (m['toAmfi'] as num?)?.toInt(),
        toName: m['toName'] as String?,
        amount: (m['amount'] as num?)?.toDouble(),
      );
}

String _k(String hash) => 'suggest_edit/$hash';

@Riverpod(keepAlive: true)
class SuggestionEdits extends _$SuggestionEdits {
  @override
  Map<String, SuggestionEdit> build() {
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    final out = <String, SuggestionEdit>{};
    for (final k in box.keys) {
      if (k is String && k.startsWith('suggest_edit/')) {
        final raw = box.get(k);
        if (raw is Map) {
          final hash = k.substring('suggest_edit/'.length);
          out[hash] = SuggestionEdit.fromJson(raw);
        }
      }
    }
    return out;
  }

  SuggestionEdit? get(String hash) => state[hash];

  Future<void> save(String hash, SuggestionEdit edit) async {
    // Set state synchronously BEFORE await so pumpAndSettle sees the new
    // state without runAsync. (See selected_member_provider.dart for pattern.)
    state = {...state, hash: edit};
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    await box.put(_k(hash), edit.toJson());
  }

  Future<void> clear(String hash) async {
    final next = {...state}..remove(hash);
    state = next;
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    await box.delete(_k(hash));
  }
}

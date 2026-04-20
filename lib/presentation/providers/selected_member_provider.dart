import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_constants.dart';

part 'selected_member_provider.g.dart';

const _prefKey = 'selected_member_id';

/// Persisted in `user_prefs` so it survives `go_router` rebuild events that
/// previously reset per-screen `_selectedMemberId` state. `null` means
/// "All members" (family aggregate view).
@Riverpod(keepAlive: true)
class SelectedMember extends _$SelectedMember {
  @override
  String? build() {
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    final raw = box.get(_prefKey);
    return raw is String ? raw : null;
  }

  /// State is set synchronously before the Hive write so the UI reflects the
  /// new selection immediately. Callers may `await` to ensure persistence has
  /// landed before navigation or app-backgrounding.
  Future<void> select(String? memberId) async {
    state = memberId;
    final box = Hive.box<dynamic>(AppConstants.hiveBoxUserPrefs);
    if (memberId == null) {
      await box.delete(_prefKey);
    } else {
      await box.put(_prefKey, memberId);
    }
  }
}

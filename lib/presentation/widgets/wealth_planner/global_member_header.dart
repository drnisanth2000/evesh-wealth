import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/selected_member_provider.dart';
import '../common/member_selector.dart';

/// Global, persisted family-member chip selector. Drop into any screen header
/// to keep member context consistent across the app. Reads/writes
/// [selectedMemberProvider] (backed by Hive `user_prefs`).
class GlobalMemberHeader extends ConsumerWidget {
  const GlobalMemberHeader({super.key, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedMemberProvider);
    return Padding(
      padding: padding,
      child: MemberSelector(
        selectedMemberId: selectedId,
        onSelected: (id) =>
            ref.read(selectedMemberProvider.notifier).select(id),
      ),
    );
  }
}

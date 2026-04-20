// lib/presentation/providers/suggestion_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'suggestion_provider.g.dart';

@riverpod
class SurplusAmountNotifier extends _$SurplusAmountNotifier {
  @override
  double build() => 10000;
  void set(double v) => state = v;
}

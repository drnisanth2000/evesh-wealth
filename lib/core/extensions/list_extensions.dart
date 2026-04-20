extension ListExtension<T> on List<T> {
  /// Group list elements by a key function
  Map<K, List<T>> groupBy<K>(K Function(T) keyFn) {
    final result = <K, List<T>>{};
    for (final item in this) {
      final key = keyFn(item);
      (result[key] ??= []).add(item);
    }
    return result;
  }

  /// Safe first element (null if empty)
  T? get firstOrNull => isEmpty ? null : first;

  /// Sum numeric values
  double sumBy(double Function(T) valueFn) {
    return fold(0.0, (sum, item) => sum + valueFn(item));
  }

  /// Min / max
  T? minBy<C extends Comparable>(C Function(T) compareFn) {
    if (isEmpty) return null;
    return reduce((a, b) => compareFn(a).compareTo(compareFn(b)) <= 0 ? a : b);
  }

  T? maxBy<C extends Comparable>(C Function(T) compareFn) {
    if (isEmpty) return null;
    return reduce((a, b) => compareFn(a).compareTo(compareFn(b)) >= 0 ? a : b);
  }

  /// Sliding window pairs for return calculation
  Iterable<(T, T)> get consecutivePairs sync* {
    for (var i = 0; i < length - 1; i++) {
      yield (this[i], this[i + 1]);
    }
  }
}

extension DoubleListExtension on List<double> {
  double get mean {
    if (isEmpty) return 0;
    return fold(0.0, (a, b) => a + b) / length;
  }

  double get variance {
    if (length < 2) return 0;
    final m = mean;
    return fold(0.0, (sum, x) => sum + (x - m) * (x - m)) / (length - 1);
  }

  double get stdDev => length < 2 ? 0 : variance < 0 ? 0 : variance == 0 ? 0 : _sqrt(variance);

  double get downsideDeviation {
    if (isEmpty) return 0;
    final negReturns = where((r) => r < 0).toList();
    if (negReturns.isEmpty) return 0;
    final meanNeg = negReturns.mean;
    final variance = negReturns.fold(0.0, (sum, r) => sum + (r - meanNeg) * (r - meanNeg)) / negReturns.length;
    return _sqrt(variance);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 50; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

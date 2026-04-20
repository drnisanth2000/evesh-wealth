import 'package:intl/intl.dart';

extension NumberFormatExtension on num {
  /// Format as Indian Rupee: ₹1,23,456.78
  String toINR({int decimals = 2, bool compact = false}) {
    if (compact) return toINRCompact();
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    );
    return formatter.format(this);
  }

  /// Format as compact INR: ₹1.23L, ₹12.5Cr
  String toINRCompact() {
    final abs = this.abs();
    final sign = this < 0 ? '-' : '';
    if (abs >= 1e7) {
      return '${sign}₹${(abs / 1e7).toStringAsFixed(abs >= 1e8 ? 1 : 2)}Cr';
    } else if (abs >= 1e5) {
      return '${sign}₹${(abs / 1e5).toStringAsFixed(abs >= 1e6 ? 1 : 2)}L';
    } else if (abs >= 1e3) {
      return '${sign}₹${(abs / 1e3).toStringAsFixed(1)}K';
    }
    return '${sign}₹${abs.toStringAsFixed(0)}';
  }

  /// Format as percentage: 12.34%
  String toPercent({int decimals = 2, bool showSign = false}) {
    final sign = showSign && this > 0 ? '+' : '';
    return '$sign${toStringAsFixed(decimals)}%';
  }

  /// Format units: 123.4567 → 123.4567 (max 4 decimals)
  String toUnits() {
    if (this == this.truncate()) return toStringAsFixed(0);
    return toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '');
  }

  /// Format NAV: 2 decimals for > 100, 4 decimals for < 100
  String toNAV() {
    if (this.abs() >= 100) return '₹${toStringAsFixed(2)}';
    return '₹${toStringAsFixed(4)}';
  }

  /// CAGR / XIRR label: +12.45% or -3.20%
  String toReturnLabel() {
    final sign = this >= 0 ? '+' : '';
    return '$sign${toStringAsFixed(2)}%';
  }

  /// Gain/loss coloring helper
  bool get isGain => this > 0;
  bool get isLoss => this < 0;
}

extension NullableNumberExtension on num? {
  String toINROrDash({int decimals = 2}) {
    if (this == null) return '—';
    return this!.toINR(decimals: decimals);
  }

  String toPercentOrDash({int decimals = 2}) {
    if (this == null) return '—';
    return this!.toPercent(decimals: decimals);
  }

  String toReturnOrDash() {
    if (this == null) return '—';
    return this!.toReturnLabel();
  }
}

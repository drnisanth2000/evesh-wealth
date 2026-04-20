/// Lightweight, hand-written model for AMFI daily performance fields.
///
/// Kept separate from [FundModel] (which is freezed-generated) so that adding
/// new columns from migration 022_fund_performance_amfi.sql does not require
/// re-running build_runner on every environment. This class is intentionally
/// plain Dart — no code generation.
library;

import 'fund_model.dart';

class FundPerformanceRow {
  final double? navDirect;
  final double? return7d;
  final double? return15d;
  final double? return1m;
  final double? return3m;
  final double? return6m;
  final double? return10y;

  final double? returnDirect1y;
  final double? returnDirect3y;
  final double? returnDirect5y;
  final double? returnDirect10y;

  final double? returnBench1y;
  final double? returnBench3y;
  final double? returnBench5y;
  final double? returnBench10y;

  final double? infoRatio1y;
  final double? infoRatio3y;
  final double? infoRatio5y;
  final double? infoRatio10y;

  final String? riskometerScheme;
  final String? riskometerBench;
  final String? returnsSource;
  final DateTime? returnsUpdatedAt;

  const FundPerformanceRow({
    this.navDirect,
    this.return7d,
    this.return15d,
    this.return1m,
    this.return3m,
    this.return6m,
    this.return10y,
    this.returnDirect1y,
    this.returnDirect3y,
    this.returnDirect5y,
    this.returnDirect10y,
    this.returnBench1y,
    this.returnBench3y,
    this.returnBench5y,
    this.returnBench10y,
    this.infoRatio1y,
    this.infoRatio3y,
    this.infoRatio5y,
    this.infoRatio10y,
    this.riskometerScheme,
    this.riskometerBench,
    this.returnsSource,
    this.returnsUpdatedAt,
  });

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _s(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  factory FundPerformanceRow.fromJson(Map<String, dynamic> json) {
    return FundPerformanceRow(
      navDirect: _d(json['nav_direct']),
      return7d: _d(json['return_7d']),
      return15d: _d(json['return_15d']),
      return1m: _d(json['return_1m']),
      return3m: _d(json['return_3m']),
      return6m: _d(json['return_6m']),
      return10y: _d(json['return_10y']),
      returnDirect1y: _d(json['return_direct_1y']),
      returnDirect3y: _d(json['return_direct_3y']),
      returnDirect5y: _d(json['return_direct_5y']),
      returnDirect10y: _d(json['return_direct_10y']),
      returnBench1y: _d(json['return_bench_1y']),
      returnBench3y: _d(json['return_bench_3y']),
      returnBench5y: _d(json['return_bench_5y']),
      returnBench10y: _d(json['return_bench_10y']),
      infoRatio1y: _d(json['info_ratio_1y']),
      infoRatio3y: _d(json['info_ratio_3y']),
      infoRatio5y: _d(json['info_ratio_5y']),
      infoRatio10y: _d(json['info_ratio_10y']),
      riskometerScheme: _s(json['riskometer_scheme']),
      riskometerBench: _s(json['riskometer_bench']),
      returnsSource: _s(json['returns_source']),
      returnsUpdatedAt: json['returns_updated_at'] != null
          ? DateTime.tryParse(json['returns_updated_at'].toString())
          : null,
    );
  }
}

/// A [FundModel] paired with its AMFI daily performance extras.
class ScreenerFundRow {
  final FundModel fund;
  final FundPerformanceRow perf;

  const ScreenerFundRow({required this.fund, required this.perf});
}

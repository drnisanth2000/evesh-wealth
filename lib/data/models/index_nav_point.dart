import 'package:freezed_annotation/freezed_annotation.dart';

part 'index_nav_point.freezed.dart';
part 'index_nav_point.g.dart';

/// One row of `index_nav_history` — used by the benchmark comparison chart.
@freezed
class IndexNavPoint with _$IndexNavPoint {
  const factory IndexNavPoint({
    @JsonKey(name: 'index_name') required String indexName,
    @JsonKey(name: 'nav_date') required DateTime navDate,
    required double nav,
  }) = _IndexNavPoint;

  factory IndexNavPoint.fromJson(Map<String, dynamic> json) =>
      _$IndexNavPointFromJson(json);
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'index_nav_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

IndexNavPoint _$IndexNavPointFromJson(Map<String, dynamic> json) {
  return _IndexNavPoint.fromJson(json);
}

/// @nodoc
mixin _$IndexNavPoint {
  @JsonKey(name: 'index_name')
  String get indexName => throw _privateConstructorUsedError;
  @JsonKey(name: 'nav_date')
  DateTime get navDate => throw _privateConstructorUsedError;
  double get nav => throw _privateConstructorUsedError;

  /// Serializes this IndexNavPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IndexNavPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IndexNavPointCopyWith<IndexNavPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IndexNavPointCopyWith<$Res> {
  factory $IndexNavPointCopyWith(
          IndexNavPoint value, $Res Function(IndexNavPoint) then) =
      _$IndexNavPointCopyWithImpl<$Res, IndexNavPoint>;
  @useResult
  $Res call(
      {@JsonKey(name: 'index_name') String indexName,
      @JsonKey(name: 'nav_date') DateTime navDate,
      double nav});
}

/// @nodoc
class _$IndexNavPointCopyWithImpl<$Res, $Val extends IndexNavPoint>
    implements $IndexNavPointCopyWith<$Res> {
  _$IndexNavPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IndexNavPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? indexName = null,
    Object? navDate = null,
    Object? nav = null,
  }) {
    return _then(_value.copyWith(
      indexName: null == indexName
          ? _value.indexName
          : indexName // ignore: cast_nullable_to_non_nullable
              as String,
      navDate: null == navDate
          ? _value.navDate
          : navDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nav: null == nav
          ? _value.nav
          : nav // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IndexNavPointImplCopyWith<$Res>
    implements $IndexNavPointCopyWith<$Res> {
  factory _$$IndexNavPointImplCopyWith(
          _$IndexNavPointImpl value, $Res Function(_$IndexNavPointImpl) then) =
      __$$IndexNavPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'index_name') String indexName,
      @JsonKey(name: 'nav_date') DateTime navDate,
      double nav});
}

/// @nodoc
class __$$IndexNavPointImplCopyWithImpl<$Res>
    extends _$IndexNavPointCopyWithImpl<$Res, _$IndexNavPointImpl>
    implements _$$IndexNavPointImplCopyWith<$Res> {
  __$$IndexNavPointImplCopyWithImpl(
      _$IndexNavPointImpl _value, $Res Function(_$IndexNavPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of IndexNavPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? indexName = null,
    Object? navDate = null,
    Object? nav = null,
  }) {
    return _then(_$IndexNavPointImpl(
      indexName: null == indexName
          ? _value.indexName
          : indexName // ignore: cast_nullable_to_non_nullable
              as String,
      navDate: null == navDate
          ? _value.navDate
          : navDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      nav: null == nav
          ? _value.nav
          : nav // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IndexNavPointImpl implements _IndexNavPoint {
  const _$IndexNavPointImpl(
      {@JsonKey(name: 'index_name') required this.indexName,
      @JsonKey(name: 'nav_date') required this.navDate,
      required this.nav});

  factory _$IndexNavPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$IndexNavPointImplFromJson(json);

  @override
  @JsonKey(name: 'index_name')
  final String indexName;
  @override
  @JsonKey(name: 'nav_date')
  final DateTime navDate;
  @override
  final double nav;

  @override
  String toString() {
    return 'IndexNavPoint(indexName: $indexName, navDate: $navDate, nav: $nav)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IndexNavPointImpl &&
            (identical(other.indexName, indexName) ||
                other.indexName == indexName) &&
            (identical(other.navDate, navDate) || other.navDate == navDate) &&
            (identical(other.nav, nav) || other.nav == nav));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, indexName, navDate, nav);

  /// Create a copy of IndexNavPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IndexNavPointImplCopyWith<_$IndexNavPointImpl> get copyWith =>
      __$$IndexNavPointImplCopyWithImpl<_$IndexNavPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IndexNavPointImplToJson(
      this,
    );
  }
}

abstract class _IndexNavPoint implements IndexNavPoint {
  const factory _IndexNavPoint(
      {@JsonKey(name: 'index_name') required final String indexName,
      @JsonKey(name: 'nav_date') required final DateTime navDate,
      required final double nav}) = _$IndexNavPointImpl;

  factory _IndexNavPoint.fromJson(Map<String, dynamic> json) =
      _$IndexNavPointImpl.fromJson;

  @override
  @JsonKey(name: 'index_name')
  String get indexName;
  @override
  @JsonKey(name: 'nav_date')
  DateTime get navDate;
  @override
  double get nav;

  /// Create a copy of IndexNavPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IndexNavPointImplCopyWith<_$IndexNavPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_order_model.freezed.dart';
part 'pending_order_model.g.dart';

@freezed
class PendingOrderModel with _$PendingOrderModel {
  const factory PendingOrderModel({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'family_id') String? familyId,
    @JsonKey(name: 'member_id') String? memberId,
    @JsonKey(name: 'amfi_code') int? amfiCode,
    @JsonKey(name: 'fund_name') required String fundName,
    @JsonKey(name: 'asset_type') @Default('MF') String assetType,
    @JsonKey(name: 'order_kind') required String orderKind,
    @JsonKey(name: 'switch_to_amfi') int? switchToAmfi,
    double? amount,
    double? units,
    @Default('placed') String status,
    @Default('manual') String source,
    @JsonKey(name: 'source_ref') String? sourceRef,
    String? notes,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'executed_at') String? executedAt,
  }) = _PendingOrderModel;

  factory PendingOrderModel.fromJson(Map<String, dynamic> json) =>
      _$PendingOrderModelFromJson(json);
}

enum OrderKind {
  buy,
  sip,
  lumpsum,
  switchOrder,
  swp,
  sell,
  gift;

  String get dbValue => switch (this) {
        OrderKind.buy => 'buy',
        OrderKind.sip => 'sip',
        OrderKind.lumpsum => 'lumpsum',
        OrderKind.switchOrder => 'switch',
        OrderKind.swp => 'swp',
        OrderKind.sell => 'sell',
        OrderKind.gift => 'gift',
      };

  String get displayName => switch (this) {
        OrderKind.buy => 'Buy',
        OrderKind.sip => 'SIP',
        OrderKind.lumpsum => 'Lumpsum',
        OrderKind.switchOrder => 'Switch',
        OrderKind.swp => 'SWP',
        OrderKind.sell => 'Sell',
        OrderKind.gift => 'Gift',
      };

  static OrderKind fromDb(String s) => switch (s) {
        'buy' => OrderKind.buy,
        'sip' => OrderKind.sip,
        'lumpsum' => OrderKind.lumpsum,
        'switch' => OrderKind.switchOrder,
        'swp' => OrderKind.swp,
        'sell' => OrderKind.sell,
        'gift' => OrderKind.gift,
        _ => throw ArgumentError.value(s, 'order_kind'),
      };
}

enum OrderStatus {
  draft,
  placed,
  executed,
  cancelled;

  String get displayName => switch (this) {
        OrderStatus.draft => 'Draft',
        OrderStatus.placed => 'Placed',
        OrderStatus.executed => 'Executed',
        OrderStatus.cancelled => 'Cancelled',
      };

  bool get isOpen => this == OrderStatus.draft || this == OrderStatus.placed;
}

enum OrderSource { manual, rebalance, deployment, watchlist }

extension PendingOrderHelpers on PendingOrderModel {
  OrderKind get kind => OrderKind.fromDb(orderKind);
  OrderStatus get statusEnum => OrderStatus.values.byName(status);
}

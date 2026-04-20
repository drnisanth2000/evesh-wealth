import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/pending_order_model.dart';
import 'auth_provider.dart';

part 'pending_orders_provider.g.dart';

/// Pending orders for a single member (or all when [memberId] is null).
/// Sorted newest-first by `created_at`.
@riverpod
Future<List<PendingOrderModel>> pendingOrders(
  PendingOrdersRef ref,
  String? memberId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final client = ref.watch(supabaseClientProvider);
  var query = client.from('pending_orders').select().eq('owner_id', userId);
  if (memberId != null) {
    query = query.eq('member_id', memberId);
  }
  final rows = await query.order('created_at', ascending: false);
  return (rows as List)
      .cast<Map<String, dynamic>>()
      .map(PendingOrderModel.fromJson)
      .toList();
}

@riverpod
class PendingOrdersMutator extends _$PendingOrdersMutator {
  @override
  void build() {}

  Future<String> add({
    required String fundName,
    required OrderKind kind,
    String? memberId,
    String? familyId,
    int? amfiCode,
    int? switchToAmfi,
    String assetType = 'MF',
    double? amount,
    double? units,
    OrderStatus status = OrderStatus.placed,
    OrderSource source = OrderSource.manual,
    String? sourceRef,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');

    final payload = <String, dynamic>{
      'owner_id': userId,
      if (familyId != null) 'family_id': familyId,
      if (memberId != null) 'member_id': memberId,
      if (amfiCode != null) 'amfi_code': amfiCode,
      'fund_name': fundName,
      'asset_type': assetType,
      'order_kind': kind.dbValue,
      if (switchToAmfi != null) 'switch_to_amfi': switchToAmfi,
      if (amount != null) 'amount': amount,
      if (units != null) 'units': units,
      'status': status.name,
      'source': source.name,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (notes != null) 'notes': notes,
    };
    final inserted = await client
        .from('pending_orders')
        .insert(payload)
        .select('id')
        .single();
    ref.invalidate(pendingOrdersProvider);
    return inserted['id'] as String;
  }

  Future<void> markStatus(String id, OrderStatus status) async {
    final client = ref.read(supabaseClientProvider);
    final payload = <String, dynamic>{
      'status': status.name,
      if (status == OrderStatus.executed)
        'executed_at': DateTime.now().toUtc().toIso8601String(),
    };
    await client.from('pending_orders').update(payload).eq('id', id);
    ref.invalidate(pendingOrdersProvider);
  }

  Future<void> cancel(String id) => markStatus(id, OrderStatus.cancelled);
  Future<void> markExecuted(String id) => markStatus(id, OrderStatus.executed);
  Future<void> markPlaced(String id) => markStatus(id, OrderStatus.placed);
}

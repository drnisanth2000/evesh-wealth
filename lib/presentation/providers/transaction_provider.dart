import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/asset_classes.dart';
import '../../data/models/transaction_model.dart';
import 'auth_provider.dart';
import 'portfolio_provider.dart';

part 'transaction_provider.g.dart';

/// Insert a single transaction; returns null on success or error message.
@riverpod
class TransactionNotifier extends _$TransactionNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> addTransaction(TransactionInput input) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return 'Not authenticated';

      final dedupHash = _computeHash(input);

      final row = {
        'owner_id': userId,
        'family_id': input.familyId,
        'member_id': input.memberId,
        'amfi_code': input.amfiCode,
        'isin': input.isin,
        'asset_type': input.assetType.dbValue,
        'asset_name': input.assetName,
        'tx_date': input.txDate,
        'tx_type': input.txType.displayName,
        'units': input.units,
        'nav_at_tx': input.navAtTx,
        'amount': input.amount,
        'folio_number': input.folioNumber,
        'broker': input.broker,
        'notes': input.notes,
        'target_amount': input.targetAmount,
        'stoploss_amount': input.stoplossAmount,
        'current_value': input.currentValue,
        'dedup_hash': dedupHash,
        'import_source': 'manual',
      };

      final response = await client.from('transactions').insert(row);
      state = const AsyncData(null);

      // Invalidate all downstream providers so dashboard/portfolio refresh
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(latestNavMapProvider);

      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      if (e.toString().contains('23505')) {
        return 'Duplicate transaction — same fund, date, amount, and type already exists.';
      }
      return e.toString();
    }
  }

  Future<String?> updateTransaction(String txId, TransactionInput input) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);

      final dedupHash = _computeHash(input);

      final row = {
        'member_id': input.memberId,
        'amfi_code': input.amfiCode,
        'isin': input.isin,
        'asset_type': input.assetType.dbValue,
        'asset_name': input.assetName,
        'tx_date': input.txDate,
        'tx_type': input.txType.displayName,
        'units': input.units,
        'nav_at_tx': input.navAtTx,
        'amount': input.amount,
        'folio_number': input.folioNumber,
        'broker': input.broker,
        'notes': input.notes,
        'target_amount': input.targetAmount,
        'stoploss_amount': input.stoplossAmount,
        'current_value': input.currentValue,
        'dedup_hash': dedupHash,
      };

      await client.from('transactions').update(row).eq('id', txId);
      state = const AsyncData(null);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(latestNavMapProvider);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> deleteTransaction(String txId) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');
      await client
          .from('transactions')
          .delete()
          .eq('id', txId)
          .eq('owner_id', userId);
      state = const AsyncData(null);
      ref.invalidate(allTransactionsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(latestNavMapProvider);
      return null;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  String _computeHash(TransactionInput input) {
    final parts = [
      input.amfiCode?.toString() ?? input.isin ?? input.assetName ?? '',
      input.txDate,
      input.amount.abs().toStringAsFixed(2),
      input.txType.name,
      input.memberId ?? '',
    ].join('|');
    return sha256.convert(utf8.encode(parts)).toString();
  }
}

/// Input DTO for a new transaction.
class TransactionInput {
  const TransactionInput({
    this.familyId,
    this.memberId,
    this.amfiCode,
    this.isin,
    this.assetName,
    required this.assetType,
    required this.txDate,
    required this.txType,
    this.units,
    this.navAtTx,
    required this.amount,
    this.folioNumber,
    this.broker,
    this.notes,
    this.targetAmount,
    this.stoplossAmount,
    this.currentValue,
  });

  final String? familyId;
  final String? memberId;
  final int? amfiCode;
  final String? isin;
  final String? assetName;
  final AssetType assetType;
  final String txDate;        // ISO date "2024-01-15"
  final TransactionType txType;
  final double? units;
  final double? navAtTx;
  final double amount;
  final String? folioNumber;
  final String? broker;
  final String? notes;
  final double? targetAmount;
  final double? stoplossAmount;
  final double? currentValue;
}

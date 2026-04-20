import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

/// Manages offline transaction queueing and sync on reconnect.
///
/// When the user is offline, pending transactions are serialised to
/// a Hive box. When connectivity is restored the service drains the
/// queue by inserting them into Supabase.
///
/// Usage:
///   await SyncService.instance.initialize();
///   SyncService.instance.enqueue(txJson);   // called by TransactionNotifier
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  static const _boxName = AppConstants.hiveBoxPendingTransactions;

  late final Box<String> _box;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _isOnline = true;

  Future<void> initialize() async {
    // Hive.initFlutter() is already called in main.dart before runApp
    _box = await Hive.openBox<String>(_boxName);

    // Check current connectivity
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    // Watch connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (wasOffline && _isOnline) {
        _drainQueue();
      }
    });

    // Drain any leftover entries from a previous session
    if (_isOnline && _box.isNotEmpty) {
      _drainQueue();
    }
  }

  bool get isOnline => _isOnline;

  /// Add a serialised transaction map to the offline queue.
  Future<void> enqueue(Map<String, dynamic> txJson) async {
    await _box.add(jsonEncode(txJson));
  }

  /// How many transactions are waiting to be synced.
  int get pendingCount => _box.length;

  /// Attempt to insert all queued transactions into Supabase.
  Future<void> _drainQueue() async {
    if (_box.isEmpty) return;

    final supabase = Supabase.instance.client;
    final keys = _box.keys.toList();

    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) continue;

      try {
        final tx = jsonDecode(raw) as Map<String, dynamic>;
        await supabase.from('transactions').insert(tx);
        await _box.delete(key);
      } catch (e) {
        // Leave in queue and retry next time
        break;
      }
    }
  }

  /// Force a manual sync attempt (e.g. on pull-to-refresh).
  Future<void> syncNow() async {
    if (_isOnline) await _drainQueue();
  }

  Future<void> dispose() async {
    await _connectivitySub.cancel();
    await _box.close();
  }
}

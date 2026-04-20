import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'services/notification_service.dart';
import 'services/pwa_service.dart';
import 'services/sync_service.dart';

// ─── Background FCM message handler (must be top-level function) ──────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This runs in a separate isolate when app is terminated
  debugPrint('Background FCM message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase ──────────────────────────────────────────────────────────────
  assert(
    AppConstants.supabaseUrl.isNotEmpty && AppConstants.supabaseAnonKey.isNotEmpty,
    'SUPABASE_URL and SUPABASE_ANON_KEY must be set via --dart-define',
  );

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // ── Hive (local storage / offline cache) ──────────────────────────────────
  await Hive.initFlutter();
  await _openHiveBoxes();

  // ── Firebase (FCM push notifications) ────────────────────────────────────
  bool firebaseReady = false;
  if (!kIsWeb || _isWebFcmConfigured()) {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          projectId: AppConstants.firebaseProjectId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          appId: AppConstants.firebaseAppId,
        ),
      );
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  // ── Services ──────────────────────────────────────────────────────────────
  await SyncService.instance.initialize();
  PwaService.instance.initialize();
  if (firebaseReady) {
    try {
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('NotificationService init skipped: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: EVeshApp(),
    ),
  );
}

Future<void> _openHiveBoxes() async {
  // pending_transactions is opened as Box<String> by SyncService.initialize()
  await Future.wait([
    Hive.openBox<dynamic>(AppConstants.hiveBoxNavCache),
    Hive.openBox<dynamic>(AppConstants.hiveBoxFundList),
    Hive.openBox<dynamic>(AppConstants.hiveBoxPortfolioSnapshot),
    Hive.openBox<dynamic>(AppConstants.hiveBoxUserPrefs),
  ]);
}

bool _isWebFcmConfigured() {
  return AppConstants.firebaseApiKey.isNotEmpty &&
      AppConstants.firebaseApiKey != 'placeholder' &&
      AppConstants.firebaseProjectId.isNotEmpty &&
      AppConstants.firebaseProjectId != 'placeholder';
}

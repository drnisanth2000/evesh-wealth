import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles FCM push notifications on both web and mobile.
///
/// - Requests permission on first launch
/// - Registers the device/browser FCM token with Supabase user profile
/// - Shows local notifications for foreground messages on mobile
/// - Exposes a stream of tapped notifications for navigation
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localPlugin = FlutterLocalNotificationsPlugin();

  final _tapController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationTap => _tapController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permission (iOS / web)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications (Android/iOS foreground display)
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _localPlugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (details) {
          // Navigate on tap — payload is JSON encoded RemoteMessage body
        },
      );

      // Android notification channel
      const channel = AndroidNotificationChannel(
        'evesh_alerts',
        'eVesh Alerts',
        description: 'Portfolio alerts from eVesh',
        importance: Importance.high,
      );
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Get token
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      await _syncTokenToSupabase(_fcmToken!);
    }

    // Refresh token
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _syncTokenToSupabase(token);
    });

    // Foreground messages (mobile only — web handles them natively)
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }

    // Background / terminated message tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _tapController.add(message);
    });

    // Check if app opened from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _tapController.add(initial);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'evesh_alerts',
          'eVesh Alerts',
          channelDescription: 'Portfolio alerts from eVesh',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Syncs FCM token to Supabase profiles table.
  Future<void> _syncTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  void dispose() {
    _tapController.close();
  }
}

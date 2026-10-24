import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] Handling message ID: ${message.messageId}');
  if (message.notification != null) {
    debugPrint('[FCM Background] Title: ${message.notification?.title}, Body: ${message.notification?.body}');
  }
}

/// Centralized service to manage Firebase Cloud Messaging (FCM) push notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM, request permissions, and register handlers
  Future<void> initialize() async {
    try {
      // 1. Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request user permissions (especially for Android 13+ POST_NOTIFICATIONS)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[NotificationService] Permission status: ${settings.authorizationStatus}');

      // 3. Listen for FCM registration token and register
      _fcm.onRegistered.listen((token) {
        _fcmToken = token;
        debugPrint('[NotificationService] FCM Token: $token');
        AnalyticsService.instance.logEvent(
          name: 'fcm_registered',
          parameters: {'has_token': 1},
        );
      });

      try {
        await _fcm.register();
      } catch (e) {
        debugPrint('[NotificationService] Error during FCM register: $e');
      }

      // 4. Subscribe to default broadcast topics
      await _subscribeToDefaultTopics();

      // 5. Setup foreground notification listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground message received: ${message.notification?.title}');
        AnalyticsService.instance.logEvent(
          name: 'notification_received_foreground',
          parameters: {
            'message_id': message.messageId ?? 'unknown',
            'title': message.notification?.title ?? '',
          },
        );
      });

      // 6. Handle notification click when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Notification opened from background: ${message.data}');
        AnalyticsService.instance.logEvent(
          name: 'notification_opened',
          parameters: {
            'message_id': message.messageId ?? 'unknown',
            'from': 'background',
          },
        );
      });

      // 7. Check if app was launched directly from terminated state by a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[NotificationService] App launched from terminated state via notification: ${initialMessage.data}');
        AnalyticsService.instance.logEvent(
          name: 'notification_opened',
          parameters: {
            'message_id': initialMessage.messageId ?? 'unknown',
            'from': 'terminated',
          },
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Error initializing Firebase Messaging: $e');
    }
  }

  /// Subscribe user to default notification channels/topics
  Future<void> _subscribeToDefaultTopics() async {
    try {
      await _fcm.subscribeToTopic('all_users');
      await _fcm.subscribeToTopic('announcements');
      debugPrint('[NotificationService] Subscribed to default topics (all_users, announcements).');
    } catch (e) {
      debugPrint('[NotificationService] Error subscribing to topics: $e');
    }
  }

  /// Subscribe to custom user topic (e.g., photo tips, new filters)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[NotificationService] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[NotificationService] Failed to subscribe to $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[NotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[NotificationService] Failed to unsubscribe from $topic: $e');
    }
  }
}

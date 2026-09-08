import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'core/api_service.dart';
import 'notification_helper.dart';

/// FCM lifecycle for notifications that must arrive while the app is closed.
/// OTP is intentionally not handled here; it is sent by email.
class PushNotificationService {
  static bool _ready = false;

  static Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        if (notification != null) {
          await NotificationHelper.showPushNotification(
            notification.title ?? 'BoulotMan',
            notification.body ?? '',
          );
        }
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await registerToken(token);
      });

      final token = await messaging.getToken();
      if (token != null) await registerToken(token);
      _ready = true;
    } catch (error) {
      // Firebase config is supplied per platform. Keep the app usable when it
      // has not been added yet or when the user denies notification permission.
      debugPrint('Push notification setup unavailable: $error');
    }
  }

  static Future<void> registerToken(String token) async {
    if (token.isEmpty) return;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ApiService().registerPushToken(token, platform);
    } catch (error) {
      debugPrint('Could not register push token: $error');
    }
  }

  static bool get isReady => _ready;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM displays notification payloads automatically while the app is closed.
  // Data-only messages are intentionally not synthesized here because the
  // backend always sends a notification payload for user-visible events.
}

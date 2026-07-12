import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:universal_html/html.dart' as html;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings: initSettings);

      // Explicitly request permissions at runtime for iOS & Android
      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      } catch (e) {
        debugPrint('Failed to request Darwin notification permissions: $e');
      }

      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Failed to request Android notification permissions: $e');
      }
    }
    _initialized = true;
  }

  static Future<void> showNotification(String title, String body) async {
    await initialize();

    if (kIsWeb) {
      // Browser notification
      try {
        final permission = html.Notification.permission;
        if (permission == 'granted') {
          html.Notification(title, body: body);
        } else if (permission != 'denied') {
          html.Notification.requestPermission().then((value) {
            if (value == 'granted') {
              html.Notification(title, body: body);
            }
          });
        }
      } catch (e) {
        debugPrint('Web Notification error: $e');
      }
    } else {
      // Native iOS / Android local notification
      try {
        const androidDetails = AndroidNotificationDetails(
          'otp_channel',
          'OTP Notifications',
          channelDescription: 'OTP notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.show(
          id: DateTime.now().hashCode & 0x7FFFFFFF, // Ensure positive 32-bit int
          title: title,
          body: body,
          notificationDetails: details,
        );
      } catch (e) {
        debugPrint('Native Notification error: $e');
      }
    }
  }
}

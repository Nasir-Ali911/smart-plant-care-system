import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:smart_plant_care/firebase_options.dart';

/// Handles Firebase Cloud Messaging for Smart Plant Care.
///
/// Responsibilities:
/// - Request notification permission
/// - Obtain FCM device token
/// - Listen for token changes
/// - Handle foreground messages
/// - Register background message handler
/// - Handle notification taps
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  // ============================================================
  // BACKGROUND MESSAGE HANDLER
  // ============================================================

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'FCM BACKGROUND MESSAGE: ${message.messageId}',
    );

    debugPrint(
      'FCM BACKGROUND DATA: ${message.data}',
    );
  }

  // ============================================================
  // INITIALIZE FCM
  // ============================================================

  static Future<void> initialize() async {
    // ----------------------------------------------------------
    // Register background message handler
    // ----------------------------------------------------------

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // ----------------------------------------------------------
    // Request notification permission
    // ----------------------------------------------------------

    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      'FCM PERMISSION STATUS: ${settings.authorizationStatus}',
    );

    // ----------------------------------------------------------
    // Get FCM token
    // ----------------------------------------------------------

    try {
      final String? token = await _messaging.getToken();

      if (token != null) {
        debugPrint('========================================');
        debugPrint('FCM DEVICE TOKEN');
        debugPrint(token);
        debugPrint('========================================');
      } else {
        debugPrint('FCM TOKEN: null');
      }
    } catch (e) {
      debugPrint('FCM TOKEN ERROR: $e');
    }

    // ----------------------------------------------------------
    // Listen for token refresh
    // ----------------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (String newToken) {
        debugPrint('FCM TOKEN REFRESHED');
        debugPrint(newToken);
      },
      onError: (Object error) {
        debugPrint('FCM TOKEN REFRESH ERROR: $error');
      },
    );

    // ----------------------------------------------------------
    // Foreground messages
    // ----------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint('========================================');
        debugPrint('FCM FOREGROUND MESSAGE');
        debugPrint('Message ID: ${message.messageId}');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
        debugPrint('Data: ${message.data}');
        debugPrint('========================================');
      },
    );

    // ----------------------------------------------------------
    // App opened from background notification
    // ----------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint('FCM NOTIFICATION TAP');
        debugPrint('Message ID: ${message.messageId}');
        debugPrint('Data: ${message.data}');
      },
    );

    // ----------------------------------------------------------
    // App opened from terminated state
    // ----------------------------------------------------------

    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('FCM APP OPENED FROM TERMINATED STATE');
      debugPrint(
        'Message ID: ${initialMessage.messageId}',
      );
      debugPrint(
        'Data: ${initialMessage.data}',
      );
    }
  }
}
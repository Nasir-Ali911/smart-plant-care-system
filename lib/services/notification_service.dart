import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:smart_plant_care/firebase_options.dart';
import 'package:smart_plant_care/services/firestore_service.dart';

/// Handles Firebase Cloud Messaging for Smart Plant Care.
///
/// Responsibilities:
/// - Request notification permission
/// - Obtain FCM device token
/// - Save FCM token to the logged-in user's Firestore profile
/// - Listen for token changes
/// - Handle foreground messages
/// - Register background message handler
/// - Handle notification taps
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirestoreService _firestoreService =
      FirestoreService();

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
  // SAVE FCM TOKEN
  // ============================================================

  /// Saves the FCM token to the currently authenticated user's
  /// Firestore profile.
  ///
  /// Firestore path:
  /// users/{uid}/fcmToken
  static Future<void> _saveTokenToFirestore(
    String token,
  ) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        debugPrint(
          'FCM TOKEN: No authenticated user. '
          'Token was not saved.',
        );
        return;
      }

      await _firestoreService.updateUserProfile(
        user.uid,
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        },
      );

      debugPrint(
        'FCM TOKEN: Successfully saved to Firestore.',
      );

      debugPrint(
        'FCM TOKEN USER UID: ${user.uid}',
      );
    } catch (e) {
      debugPrint(
        'FCM TOKEN FIRESTORE SAVE ERROR: $e',
      );
    }
  }

  // ============================================================
  // INITIALIZE FCM
  // ============================================================

  static Future<void> initialize() async {
    // ----------------------------------------------------------
    // Skip FCM initialization on Flutter Web
    // ----------------------------------------------------------

    if (kIsWeb) {
      debugPrint(
        'FCM initialization skipped on web.',
      );
      return;
    }

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
      'FCM PERMISSION STATUS: '
      '${settings.authorizationStatus}',
    );

    // ----------------------------------------------------------
    // Get FCM token
    // ----------------------------------------------------------

    try {
      final String? token =
          await _messaging.getToken();

      if (token != null) {
        debugPrint(
          '========================================',
        );

        debugPrint(
          'FCM DEVICE TOKEN',
        );

        debugPrint(token);

        debugPrint(
          '========================================',
        );

        // Save token to Firestore
        await _saveTokenToFirestore(token);
      } else {
        debugPrint(
          'FCM TOKEN: null',
        );
      }
    } catch (e) {
      debugPrint(
        'FCM TOKEN ERROR: $e',
      );
    }

    // ----------------------------------------------------------
    // Listen for token refresh
    // ----------------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (String newToken) async {
        debugPrint(
          'FCM TOKEN REFRESHED',
        );

        debugPrint(newToken);

        // Save refreshed token to Firestore
        await _saveTokenToFirestore(newToken);
      },
      onError: (Object error) {
        debugPrint(
          'FCM TOKEN REFRESH ERROR: $error',
        );
      },
    );

    // ----------------------------------------------------------
    // Foreground messages
    // ----------------------------------------------------------

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        debugPrint(
          '========================================',
        );

        debugPrint(
          'FCM FOREGROUND MESSAGE',
        );

        debugPrint(
          'Message ID: ${message.messageId}',
        );

        debugPrint(
          'Title: ${message.notification?.title}',
        );

        debugPrint(
          'Body: ${message.notification?.body}',
        );

        debugPrint(
          'Data: ${message.data}',
        );

        debugPrint(
          '========================================',
        );
      },
    );

    // ----------------------------------------------------------
    // App opened from background notification
    // ----------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint(
          'FCM NOTIFICATION TAP',
        );

        debugPrint(
          'Message ID: ${message.messageId}',
        );

        debugPrint(
          'Data: ${message.data}',
        );
      },
    );

    // ----------------------------------------------------------
    // App opened from terminated state
    // ----------------------------------------------------------

    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        'FCM APP OPENED FROM TERMINATED STATE',
      );

      debugPrint(
        'Message ID: ${initialMessage.messageId}',
      );

      debugPrint(
        'Data: ${initialMessage.data}',
      );
    }
  }
}
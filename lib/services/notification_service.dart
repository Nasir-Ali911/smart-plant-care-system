import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:smart_plant_care/firebase_options.dart';
import 'package:smart_plant_care/services/firestore_service.dart';

/// Handles Firebase Cloud Messaging for Smart Plant Care.
///
/// Responsibilities:
/// - Request notification permission
/// - Obtain FCM device token
/// - Save FCM token to the logged-in user's Firestore profile
/// - Save token automatically after login
/// - Listen for token changes
/// - Handle foreground messages
/// - Display foreground notifications
/// - Register background message handler
/// - Handle notification taps
class NotificationService {
  NotificationService._();

  // ------------------------------------------------------------
  // Firebase services
  // ------------------------------------------------------------

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirestoreService _firestoreService =
      FirestoreService();

  // ------------------------------------------------------------
  // Local notifications
  // ------------------------------------------------------------

  static final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel
      _notificationChannel =
      AndroidNotificationChannel(
    'smart_plant_care_alerts',
    'Smart Plant Care Alerts',
    description:
        'Notifications and alerts from Smart Plant Care.',
    importance: Importance.max,
    playSound: true,
  );

  // ------------------------------------------------------------
  // State
  // ------------------------------------------------------------

  static bool _initialized = false;

  static String? _currentToken;

  // ------------------------------------------------------------
  // Background FCM handler
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // Initialize local notifications
  // ------------------------------------------------------------

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings
        androidInitializationSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTap,
    );

    final AndroidFlutterLocalNotificationsPlugin?
        androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _notificationChannel,
    );

    await androidPlugin?.requestNotificationsPermission();

    debugPrint(
      'LOCAL NOTIFICATIONS: Initialized successfully.',
    );
  }

  // ------------------------------------------------------------
  // Local notification tap
  // ------------------------------------------------------------

  static void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      'LOCAL NOTIFICATION TAP',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );

    // Navigation can be added here later.
  }

  // ------------------------------------------------------------
  // Show foreground notification
  // ------------------------------------------------------------

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final String title =
        message.notification?.title ??
            message.data['title'] ??
            'Smart Plant Care';

    final String body =
        message.notification?.body ??
            message.data['body'] ??
            'You have a new notification.';

    final AndroidNotificationDetails
        androidNotificationDetails =
        AndroidNotificationDetails(
      _notificationChannel.id,
      _notificationChannel.name,
      channelDescription:
          _notificationChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidNotificationDetails,
    );

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: message.messageId,
    );

    debugPrint(
      'LOCAL NOTIFICATION: Displayed successfully.',
    );
  }

  // ------------------------------------------------------------
  // Save FCM token to Firestore
  // ------------------------------------------------------------

  static Future<void> _saveTokenToFirestore(
    String token,
  ) async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        debugPrint(
          'FCM TOKEN: No authenticated user. '
          'Token will be saved after login.',
        );
        return;
      }

      await _firestoreService.updateUserProfile(
        user.uid,
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt':
              DateTime.now().toIso8601String(),
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

  // ------------------------------------------------------------
  // Save current token after authentication
  // ------------------------------------------------------------

  static Future<void> _saveCurrentTokenForUser(
    User? user,
  ) async {
    if (user == null) {
      debugPrint(
        'FCM AUTH: No authenticated user.',
      );
      return;
    }

    final String? token = _currentToken;

    if (token == null) {
      debugPrint(
        'FCM AUTH: Token not available yet.',
      );
      return;
    }

    debugPrint(
      'FCM AUTH: User authenticated. '
      'Saving FCM token...',
    );

    await _saveTokenToFirestore(token);
  }

  // ------------------------------------------------------------
  // Main initialization
  // ------------------------------------------------------------

  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint(
        'FCM initialization skipped on web.',
      );
      return;
    }

    if (_initialized) {
      debugPrint(
        'FCM initialization already completed.',
      );
      return;
    }

    _initialized = true;

    // ----------------------------------------------------------
    // Background message handler
    // ----------------------------------------------------------

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // ----------------------------------------------------------
    // Local notifications
    // ----------------------------------------------------------

    await _initializeLocalNotifications();

    // ----------------------------------------------------------
    // FCM notification permission
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
        _currentToken = token;

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
    // Authentication listener
    // ----------------------------------------------------------

    _auth.authStateChanges().listen(
      (User? user) async {
        if (user != null) {
          debugPrint(
            'FCM AUTH: Logged-in user detected: '
            '${user.uid}',
          );

          await _saveCurrentTokenForUser(user);
        } else {
          debugPrint(
            'FCM AUTH: User signed out.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'FCM AUTH LISTENER ERROR: $error',
        );
      },
    );

    // ----------------------------------------------------------
    // FCM token refresh
    // ----------------------------------------------------------

    _messaging.onTokenRefresh.listen(
      (String newToken) async {
        debugPrint(
          'FCM TOKEN REFRESHED',
        );

        debugPrint(newToken);

        _currentToken = newToken;

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
      (RemoteMessage message) async {
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

        // Display Android notification banner.
        await _showForegroundNotification(message);
      },
    );

    // ----------------------------------------------------------
    // Notification tap - background
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
    // Notification tap - terminated app
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
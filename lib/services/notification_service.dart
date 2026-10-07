import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:smart_plant_care/firebase_options.dart';
import 'package:smart_plant_care/services/firestore_service.dart';
import 'package:smart_plant_care/services/notification_history_service.dart';
import 'package:smart_plant_care/services/notification_settings_service.dart';

/// Handles Firebase Cloud Messaging and local notifications
/// for Smart Plant Care.
///
/// Responsibilities:
/// - Request notification permission
/// - Obtain FCM device token
/// - Save FCM token to Firestore
/// - Listen for token changes
/// - Handle foreground FCM messages
/// - Save FCM messages to notification history
/// - Display foreground notifications
/// - Register background message handler
/// - Handle notification taps
/// - Generate AI recommendation notifications
/// - Respect notification ON/OFF settings
class NotificationService {
  NotificationService._();

  // ============================================================
  // Firebase services
  // ============================================================

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final FirestoreService _firestoreService =
      FirestoreService();

  static final NotificationHistoryService _historyService =
      NotificationHistoryService.instance;

  static final NotificationSettingsService _settingsService =
      NotificationSettingsService.instance;

  // ============================================================
  // Local notifications
  // ============================================================

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

  // ============================================================
  // State
  // ============================================================

  static bool _initialized = false;

  static String? _currentToken;

  // ============================================================
  // AI notification duplicate protection
  // ============================================================

  static String? _lastAIAlertKey;

  static DateTime? _lastAIAlertTime;

  // ============================================================
  // Notification settings helper
  // ============================================================

  /// Returns true when the notification is allowed by the
  /// user's notification settings.
  ///
  /// Global setting:
  ///   enabled
  ///
  /// Category settings:
  ///   soilMoisture
  ///   irrigation
  ///   environmental
  ///   deviceAlerts
  static Future<bool> _isNotificationEnabled({
    String? category,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> settings =
          await _settingsService.getSettings();

      // ----------------------------------------------------------
      // Global notification switch
      // ----------------------------------------------------------

      final bool globalEnabled =
          settings['enabled'] != false;

      if (!globalEnabled) {
        debugPrint(
          'NOTIFICATION SETTINGS: '
          'Global notifications are OFF.',
        );

        return false;
      }

      // ----------------------------------------------------------
      // Determine category
      // ----------------------------------------------------------

      final String combined =
          '${category ?? ''} ${type ?? ''}'
              .toLowerCase()
              .trim();

      // ----------------------------------------------------------
      // Soil moisture
      // ----------------------------------------------------------

      if (combined.contains('soil') ||
          combined.contains('moisture')) {
        final bool enabled =
            settings['soilMoisture'] != false;

        debugPrint(
          'NOTIFICATION SETTINGS: '
          'Soil/Moisture = $enabled',
        );

        return enabled;
      }

      // ----------------------------------------------------------
      // Irrigation
      // ----------------------------------------------------------

      if (combined.contains('irrigation') ||
          combined.contains('watering') ||
          combined.contains('water') ||
          combined.contains('pump')) {
        final bool enabled =
            settings['irrigation'] != false;

        debugPrint(
          'NOTIFICATION SETTINGS: '
          'Irrigation = $enabled',
        );

        return enabled;
      }

      // ----------------------------------------------------------
      // Environmental
      // ----------------------------------------------------------

      if (combined.contains('environment') ||
          combined.contains('temperature') ||
          combined.contains('humidity') ||
          combined.contains('light')) {
        final bool enabled =
            settings['environmental'] != false;

        debugPrint(
          'NOTIFICATION SETTINGS: '
          'Environmental = $enabled',
        );

        return enabled;
      }

      // ----------------------------------------------------------
      // Device alerts
      // ----------------------------------------------------------

      if (combined.contains('device') ||
          combined.contains('offline') ||
          combined.contains('connection') ||
          combined.contains('connectivity') ||
          combined.contains('error')) {
        final bool enabled =
            settings['deviceAlerts'] != false;

        debugPrint(
          'NOTIFICATION SETTINGS: '
          'Device Alerts = $enabled',
        );

        return enabled;
      }

      // ----------------------------------------------------------
      // Unknown/general category
      // ----------------------------------------------------------

      debugPrint(
        'NOTIFICATION SETTINGS: '
        'Unknown/general category. Global setting applies.',
      );

      return true;
    } catch (e) {
      debugPrint(
        'NOTIFICATION SETTINGS ERROR: $e',
      );

      // Fail-safe:
      // if settings cannot be read, allow the notification.
      return true;
    }
  }

  // ============================================================
  // Extract FCM notification information
  // ============================================================

  static String _getFCMTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title']?.toString() ??
        'Smart Plant Care';
  }

  static String _getFCMBody(RemoteMessage message) {
    return message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new notification.';
  }

  static String _getFCMCategory(RemoteMessage message) {
    return message.data['category']?.toString() ??
        'General';
  }

  static String _getFCMPriority(RemoteMessage message) {
    return message.data['priority']?.toString() ??
        'LOW';
  }

  static String _getFCMType(RemoteMessage message) {
    return message.data['type']?.toString() ??
        _getFCMCategory(message);
  }

  // ============================================================
  // Save FCM notification to Firebase history
  // ============================================================

  static Future<bool> _saveFCMNotificationToHistory(
    RemoteMessage message,
  ) async {
    try {
      final String title = _getFCMTitle(message);

      final String body = _getFCMBody(message);

      final String category =
          _getFCMCategory(message);

      final String priority =
          _getFCMPriority(message);

      final String type =
          _getFCMType(message);

      // ----------------------------------------------------------
      // Check notification settings
      // ----------------------------------------------------------

      final bool enabled =
          await _isNotificationEnabled(
        category: category,
        type: type,
      );

      if (!enabled) {
        debugPrint(
          'FCM HISTORY: Notification blocked by settings.',
        );

        debugPrint(
          'Category: $category',
        );

        debugPrint(
          'Type: $type',
        );

        return false;
      }

      // ----------------------------------------------------------
      // Save to Firebase
      // ----------------------------------------------------------

      final String? historyId =
          await _historyService.addNotification(
        title: title,
        message: body,
        category: category,
        priority: priority,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        messageId: message.messageId,
      );

      debugPrint(
        'FCM HISTORY: Notification saved.',
      );

      debugPrint(
        'History ID: $historyId',
      );

      debugPrint(
        'Message ID: ${message.messageId}',
      );

      return true;
    } catch (e) {
      debugPrint(
        'FCM HISTORY ERROR: $e',
      );

      return false;
    }
  }

  // ============================================================
  // Background FCM handler
  // ============================================================

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      '========================================',
    );

    debugPrint(
      'FCM BACKGROUND MESSAGE',
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

    // ----------------------------------------------------------
    // Save message to notification history.
    //
    // For Firebase notification messages, Android itself may
    // display the system notification while the app is in the
    // background. We therefore DO NOT create another local
    // notification here.
    // ----------------------------------------------------------

    await _saveFCMNotificationToHistory(message);
  }

  // ============================================================
  // Initialize local notifications
  // ============================================================

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
      settings: initializationSettings,
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

  // ============================================================
  // Local notification tap
  // ============================================================

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

  // ============================================================
  // Show foreground FCM notification
  // ============================================================

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final String title =
        _getFCMTitle(message);

    final String body =
        _getFCMBody(message);

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

    final NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidNotificationDetails,
    );

    final int notificationId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: message.messageId,
    );

    debugPrint(
      'LOCAL NOTIFICATION: Displayed successfully.',
    );
  }

  // ============================================================
  // Handle FCM message received while app is foreground
  // ============================================================

  static Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
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

    // ----------------------------------------------------------
    // Save to notification history.
    // ----------------------------------------------------------

    final bool saved =
        await _saveFCMNotificationToHistory(message);

    // ----------------------------------------------------------
    // If settings allow it, display local notification.
    // ----------------------------------------------------------

    if (!saved) {
      debugPrint(
        'FCM FOREGROUND: Notification suppressed.',
      );

      return;
    }

    await _showForegroundNotification(message);
  }

  // ============================================================
  // AI RECOMMENDATION NOTIFICATION
  // ============================================================

  /// Displays an AI-generated recommendation as a local
  /// Android notification and saves it to Firebase history.
  ///
  /// Duplicate protection prevents the exact same AI alert
  /// from being generated repeatedly within 30 minutes.
  static Future<void> notifyAIRecommendation({
    required String title,
    required String message,
    required String urgency,
    required double score,
    String category = 'Soil',
    String type = 'AI Recommendation',
  }) async {
    try {
      // ----------------------------------------------------------
      // Check notification settings
      // ----------------------------------------------------------

      final bool enabled =
          await _isNotificationEnabled(
        category: category,
        type: type,
      );

      if (!enabled) {
        debugPrint(
          'AI NOTIFICATION: Blocked by notification settings.',
        );

        return;
      }

      // ----------------------------------------------------------
      // Duplicate protection
      // ----------------------------------------------------------

      final String alertKey =
          '${title.trim()}|'
          '${message.trim()}|'
          '${urgency.trim()}';

      final DateTime now = DateTime.now();

      if (_lastAIAlertKey == alertKey &&
          _lastAIAlertTime != null &&
          now.difference(_lastAIAlertTime!).inMinutes < 30) {
        debugPrint(
          'AI NOTIFICATION: Duplicate alert suppressed.',
        );

        return;
      }

      _lastAIAlertKey = alertKey;
      _lastAIAlertTime = now;

      // ----------------------------------------------------------
      // Save notification to Firebase history
      // ----------------------------------------------------------

      final String? historyId =
          await _historyService.addNotification(
        title: title,
        message: message,
        category: category,
        priority: urgency,
        type: type,
        timestamp: now,
        isRead: false,
      );

      debugPrint(
        'AI NOTIFICATION: Saved to history: $historyId',
      );

      // ----------------------------------------------------------
      // Make sure local notifications are initialized
      // ----------------------------------------------------------

      if (!_initialized) {
        await _initializeLocalNotifications();
      }

      // ----------------------------------------------------------
      // Android notification
      // ----------------------------------------------------------

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

      final NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidNotificationDetails,
      );

      final int notificationId =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: message,
        notificationDetails: notificationDetails,
        payload: 'ai_recommendation',
      );

      debugPrint(
        'AI NOTIFICATION: Android notification displayed.',
      );

      debugPrint(
        'AI NOTIFICATION SCORE: '
        '${score.toStringAsFixed(1)}',
      );

      debugPrint(
        'AI NOTIFICATION URGENCY: $urgency',
      );
    } catch (e) {
      debugPrint(
        'AI NOTIFICATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // Save FCM token to Firestore
  // ============================================================

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

  // ============================================================
  // Save current token after authentication
  // ============================================================

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

  // ============================================================
  // Main initialization
  // ============================================================

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

    // Set this only after confirming we are on Android/iOS.
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

        // Save immediately if user is already logged in.
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
        await _handleForegroundMessage(message);
      },
    );

    // ----------------------------------------------------------
    // Notification tap - background
    // ----------------------------------------------------------

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) async {
        debugPrint(
          'FCM NOTIFICATION TAP',
        );

        debugPrint(
          'Message ID: ${message.messageId}',
        );

        debugPrint(
          'Data: ${message.data}',
        );

        // Make sure the notification exists in history.
        await _saveFCMNotificationToHistory(message);
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

      // Make sure the notification exists in history.
      await _saveFCMNotificationToHistory(
        initialMessage,
      );
    }
  }
}
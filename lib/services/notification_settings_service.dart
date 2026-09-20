import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationSettingsService {
  NotificationSettingsService._();

  static final NotificationSettingsService instance =
      NotificationSettingsService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference? get _settingsRef {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _database.ref(
      'Users/${user.uid}/NotificationSettings',
    );
  }

  // ============================================================
  // DEFAULT SETTINGS
  // ============================================================

  static const Map<String, dynamic> defaultSettings = {
    'enabled': true,
    'soilMoisture': true,
    'irrigation': true,
    'environmental': true,
    'deviceAlerts': true,
  };

  // ============================================================
  // GET SETTINGS
  // ============================================================

  Future<Map<String, dynamic>> getSettings() async {
    final DatabaseReference? ref = _settingsRef;

    if (ref == null) {
      return Map<String, dynamic>.from(
        defaultSettings,
      );
    }

    try {
      final DataSnapshot snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) {
        await saveSettings(
          Map<String, dynamic>.from(
            defaultSettings,
          ),
        );

        return Map<String, dynamic>.from(
          defaultSettings,
        );
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      return {
        'enabled':
            data['enabled'] ?? true,
        'soilMoisture':
            data['soilMoisture'] ?? true,
        'irrigation':
            data['irrigation'] ?? true,
        'environmental':
            data['environmental'] ?? true,
        'deviceAlerts':
            data['deviceAlerts'] ?? true,
      };
    } catch (e) {
      print(
        'NOTIFICATION SETTINGS ERROR: $e',
      );

      return Map<String, dynamic>.from(
        defaultSettings,
      );
    }
  }

  // ============================================================
  // SAVE SETTINGS
  // ============================================================

  Future<void> saveSettings(
    Map<String, dynamic> settings,
  ) async {
    final DatabaseReference? ref = _settingsRef;

    if (ref == null) {
      return;
    }

    await ref.set(settings);
  }

  // ============================================================
  // UPDATE ONE SETTING
  // ============================================================

  Future<void> updateSetting(
    String key,
    bool value,
  ) async {
    final DatabaseReference? ref = _settingsRef;

    if (ref == null) {
      return;
    }

    await ref.update({
      key: value,
    });
  }

  // ============================================================
  // SETTINGS STREAM
  // ============================================================

  Stream<Map<String, dynamic>> settingsStream() {
    final DatabaseReference? ref = _settingsRef;

    if (ref == null) {
      return Stream.value(
        Map<String, dynamic>.from(
          defaultSettings,
        ),
      );
    }

    return ref.onValue.map((event) {
      if (event.snapshot.value == null) {
        return Map<String, dynamic>.from(
          defaultSettings,
        );
      }

      final Map<dynamic, dynamic> data =
          event.snapshot.value as Map<dynamic, dynamic>;

      return {
        'enabled':
            data['enabled'] ?? true,
        'soilMoisture':
            data['soilMoisture'] ?? true,
        'irrigation':
            data['irrigation'] ?? true,
        'environmental':
            data['environmental'] ?? true,
        'deviceAlerts':
            data['deviceAlerts'] ?? true,
      };
    });
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Stores and manages notification history for the authenticated user.
///
/// Realtime Database structure:
///
/// Users
///   └── {uid}
///       └── Notifications
///           └── {notificationId}
///               ├── title
///               ├── message
///               ├── category
///               ├── priority
///               ├── type
///               ├── timestamp
///               └── isRead
class NotificationHistoryService {
  NotificationHistoryService._();

  static final NotificationHistoryService instance =
      NotificationHistoryService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference? get _notificationsRef {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _database.ref(
      'Users/${user.uid}/Notifications',
    );
  }

  // ============================================================
  // ADD NOTIFICATION
  // ============================================================

  Future<String?> addNotification({
    required String title,
    required String message,
    required String category,
    required String priority,
    String? type,
    DateTime? timestamp,
    bool isRead = false,
    String? messageId,
  }) async {
    try {
      final DatabaseReference? ref = _notificationsRef;

      if (ref == null) {
        return null;
      }

      final DatabaseReference notificationRef = ref.push();

      await notificationRef.set({
        'title': title,
        'message': message,
        'category': category,
        'priority': priority,
        'type': type ?? category,
        'timestamp':
            (timestamp ?? DateTime.now()).millisecondsSinceEpoch,
        'isRead': isRead,
        'messageId': messageId,
      });

      return notificationRef.key;
    } catch (e) {
      print(
        'NOTIFICATION HISTORY: Failed to save notification: $e',
      );

      return null;
    }
  }

  // ============================================================
  // MARK ONE AS READ
  // ============================================================

  Future<void> markAsRead(
    String notificationId,
  ) async {
    try {
      final DatabaseReference? ref = _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref.child(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print(
        'NOTIFICATION HISTORY: Failed to mark as read: $e',
      );
    }
  }

  // ============================================================
  // MARK ALL AS READ
  // ============================================================

  Future<void> markAllAsRead() async {
    try {
      final DatabaseReference? ref = _notificationsRef;

      if (ref == null) {
        return;
      }

      final DataSnapshot snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) {
        return;
      }

      final Map<String, dynamic> updates = {};

      for (final DataSnapshot child in snapshot.children) {
        updates['${child.key}/isRead'] = true;
      }

      if (updates.isNotEmpty) {
        await ref.update(updates);
      }
    } catch (e) {
      print(
        'NOTIFICATION HISTORY: Failed to mark all as read: $e',
      );
    }
  }

  // ============================================================
  // DELETE ONE
  // ============================================================

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    try {
      final DatabaseReference? ref = _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref.child(notificationId).remove();
    } catch (e) {
      print(
        'NOTIFICATION HISTORY: Failed to delete notification: $e',
      );
    }
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> clearAll() async {
    try {
      final DatabaseReference? ref = _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref.remove();
    } catch (e) {
      print(
        'NOTIFICATION HISTORY: Failed to clear history: $e',
      );
    }
  }
}
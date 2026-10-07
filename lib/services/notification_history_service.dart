import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationHistoryService {
  NotificationHistoryService._();

  static final NotificationHistoryService instance =
      NotificationHistoryService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseDatabase _database =
      FirebaseDatabase.instance;

  // ============================================================
  // Notifications reference
  // ============================================================

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
  // Add notification
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
      final DatabaseReference? ref =
          _notificationsRef;

      if (ref == null) {
        return null;
      }

      // ----------------------------------------------------------
      // Prevent duplicate FCM history records.
      //
      // The same FCM message can pass through:
      // - foreground handler
      // - background handler
      // - notification tap handler
      // - terminated-app handler
      //
      // messageId lets us recognize the same notification.
      // ----------------------------------------------------------

      if (messageId != null &&
          messageId.trim().isNotEmpty) {
        final DataSnapshot existing =
            await ref
                .orderByChild('messageId')
                .equalTo(messageId)
                .get();

        if (existing.exists) {
          for (final DataSnapshot child
              in existing.children) {
            if (child.key != null) {
              return child.key;
            }
          }
        }
      }

      // ----------------------------------------------------------
      // Create new history record
      // ----------------------------------------------------------

      final DatabaseReference notificationRef =
          ref.push();

      await notificationRef.set({
        'title': title,
        'message': message,
        'category': category,
        'priority': priority,
        'type': type ?? category,
        'timestamp':
            (timestamp ?? DateTime.now())
                .millisecondsSinceEpoch,
        'isRead': isRead,
        'messageId': messageId,
      });

      return notificationRef.key;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // Mark one notification as read
  // ============================================================

  Future<void> markAsRead(
    String notificationId,
  ) async {
    try {
      final DatabaseReference? ref =
          _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref
          .child(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      // Ignore individual update errors.
    }
  }

  // ============================================================
  // Mark all notifications as read
  // ============================================================

  Future<void> markAllAsRead() async {
    try {
      final DatabaseReference? ref =
          _notificationsRef;

      if (ref == null) {
        return;
      }

      final DataSnapshot snapshot =
          await ref.get();

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic> updates =
          <String, dynamic>{};

      for (final DataSnapshot child
          in snapshot.children) {
        if (child.key != null) {
          updates[
              '${child.key}/isRead'] = true;
        }
      }

      if (updates.isNotEmpty) {
        await ref.update(updates);
      }
    } catch (e) {
      // Ignore bulk update errors.
    }
  }

  // ============================================================
  // Delete one notification
  // ============================================================

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    try {
      final DatabaseReference? ref =
          _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref
          .child(notificationId)
          .remove();
    } catch (e) {
      // Ignore delete errors.
    }
  }

  // ============================================================
  // Delete all notifications
  // ============================================================

  Future<void> clearAll() async {
    try {
      final DatabaseReference? ref =
          _notificationsRef;

      if (ref == null) {
        return;
      }

      await ref.remove();
    } catch (e) {
      // Ignore clear errors.
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream notifications explicitly aimed at a specific userId
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    try {
      return _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
        
        // Parse type
        NotificationType type;
        switch (data['type']) {
          case 'registration': type = NotificationType.registration; break;
          case 'eventUpdate': type = NotificationType.eventUpdate; break;
          case 'reminder': type = NotificationType.reminder; break;
          case 'announcement': type = NotificationType.announcement; break;
          case 'profileIncomplete': type = NotificationType.profileIncomplete; break;
          default: type = NotificationType.announcement; break;
        }

        // Format simple timestamp relative logic could go here; returning raw or assumed formatted for now
        // Typically handled by UI via timeago package. For minimal change, passing existing field or generic 'just now'
        String timeStr = 'Recently';
        if (data['createdAt'] != null) {
          final DateTime dt = (data['createdAt'] as Timestamp).toDate();
          final diff = DateTime.now().difference(dt);
          if (diff.inDays > 1) {
            timeStr = '${diff.inDays} days ago';
          } else if (diff.inHours > 0) {
            timeStr = '${diff.inHours} hours ago';
          } else if (diff.inMinutes > 0) {
            timeStr = '${diff.inMinutes} mins ago';
          } else {
            timeStr = 'Just now';
          }
        }

        return NotificationModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          timestamp: timeStr,
          type: type,
          isRead: data['isRead'] ?? false,
          eventId: data['eventId'],
        );
      }).toList();
    });
    } catch (e) {
      if (kDebugMode) print('Notification Stream Error: $e');
      return Stream.value([]);
    }
  }

  /// Mark specific notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications for a user as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ─── Profile Completion Notifications ────────────────────────────────────────

  /// Creates a "Complete Your Profile" notification for a user if one doesn't
  /// already exist. Safe to call on every login — idempotent.
  Future<void> ensureProfileIncompleteNotification({
    required String userId,
    required String role, // 'student' or 'club'
  }) async {
    try {
      final existing = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'profileIncomplete')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return; // already exists, skip

      final description = role == 'club'
          ? 'Add your tagline, description, faculty mentor and location so students can know your club better.'
          : 'Add your branch, year and bio so others can know you better.';

      await _db.collection('notifications').add({
        'userId': userId,
        'title': 'Complete Your Profile ✏️',
        'description': description,
        'type': 'profileIncomplete',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) print('ensureProfileIncompleteNotification error: \$e');
    }
  }

  /// Deletes the profile-incomplete notification for a user (called after
  /// profile is fully completed and saved).
  Future<void> dismissProfileIncompleteNotification(String userId) async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'profileIncomplete')
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) print('dismissProfileIncompleteNotification error: \$e');
    }
  }

  // ─── Sending Notifications ──────────────────────────────────────────────────

  /// Send a notification to all students
  Future<void> sendBroadcast({
    required String senderClubId,
    required String title,
    required String message,
  }) async {
    // 1. Record the announcement in global history
    final announcementRef = await _db.collection('club_announcements').add({
      'senderClubId': senderClubId,
      'title': title,
      'message': message,
      'target': 'all',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create notification documents for all students
    // In a real app, this would be a Cloud Function triggered by the above write.
    // For now, we fetch all students and create notifications.
    final students = await _db.collection('users').where('role', isEqualTo: 'student').get();
    
    final batch = _db.batch();
    for (var student in students.docs) {
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': student.id,
        'title': title,
        'description': message,
        'type': 'announcement',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'announcementId': announcementRef.id,
      });
    }
    await batch.commit();
  }

  /// Send a notification to students registered for a specific event
  Future<void> sendEventAnnouncement({
    required String senderClubId,
    required String eventId,
    required String title,
    required String message,
  }) async {
    // 1. Record in history
    final announcementRef = await _db.collection('club_announcements').add({
      'senderClubId': senderClubId,
      'eventId': eventId,
      'title': title,
      'message': message,
      'target': 'event_participants',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Get registered users
    final registrations = await _db.collection('events').doc(eventId).collection('registrations').get();
    
    final batch = _db.batch();
    for (var reg in registrations.docs) {
      final userId = reg.id; // Doc ID is the userId
      final notifRef = _db.collection('notifications').doc();
      batch.set(notifRef, {
        'userId': userId,
        'title': title,
        'description': message,
        'type': 'eventUpdate',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'eventId': eventId,
        'announcementId': announcementRef.id,
      });
    }
    await batch.commit();
  }
}

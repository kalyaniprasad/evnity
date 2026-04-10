import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../features/club/models/club_event.dart';
import '../../features/club/models/registration_field_model.dart';

class EventRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Event Creation & Fetching ─────────────────────────────────────────────

  /// Create an event (Club action)
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    final docRef = await _db.collection('events').add({
      ...eventData,
      'createdAt': FieldValue.serverTimestamp(),
      'registrationCount': 0,
      'messageCount': 0,
    });

    // Auto-update event document to include the generated random ID as an explicitly queryable field if needed
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  /// Delete an event (Club action)
  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
    // Also delete registrations sub-collection and chat room... (for robustness)
  }

  /// Update an event (Club action)
  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    await _db.collection('events').doc(eventId).update({
      ...eventData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all published events
  Stream<List<EventModel>> streamEvents() {
    return _db
        .collection('events')
        .where(
          'status',
          isEqualTo: 'published',
        ) // Optional: map your EventStatus
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return EventModel(
              id: doc.id,
              title: data['title'] ?? '',
              hostClubId: data['clubId'] ?? '',
              clubName: data['clubName'] ?? '',
              organizerName:
                  data['organizerName'] ??
                  data['clubName'] ??
                  '', // Fallback for old data
              clubLogoUrl: data['clubLogoUrl'] ?? '',
              date: data['date'] ?? '',
              time: data['time'] ?? '',
              venue: data['venue'] ?? '',
              category: data['category'] ?? 'Other',
              posterUrl: data['posterUrl'] ?? '', // Cloudinary URL
              description: data['description'] ?? '',
              registrationCount: data['registrationCount'] ?? 0,
              registrationFields: (data['registrationFields'] as List<dynamic>? ?? [])
                  .map((f) => RegistrationFieldModel.fromJson(f as Map<String, dynamic>))
                  .toList(),
            );
          }).toList();
        });
  }

  /// Stream events created by a specific club
  Stream<List<ClubEvent>> streamClubEvents(String clubId) {
    return _db
        .collection('events')
        .where('clubId', isEqualTo: clubId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ClubEvent(
              id: doc.id,
              title: data['title'] ?? '',
              category: data['category'] ?? 'Other',
              date: data['date'] ?? '',
              time: data['time'] ?? '',
              venue: data['venue'] ?? '',
              posterUrl: data['posterUrl'] ?? '',
              description: data['description'] ?? '',
              status: data['status'] == 'published'
                  ? EventStatus.published
                  : EventStatus.draft,
              registrationCount: data['registrationCount'] ?? 0,
              messageCount: data['messageCount'] ?? 0,
              registrationFields: (data['registrationFields'] as List<dynamic>? ?? [])
                  .map((f) => RegistrationFieldModel.fromJson(
                      f as Map<String, dynamic>))
                  .toList(),
            );
          }).toList();
        });
  }

  // ─── Registration Transactions ─────────────────────────────────────────────

  /// Register user for an event
  /// Updates `events`, `users`, `registrations`, and `notifications` simultaneously
  Future<void> registerForEvent({
    required String eventId,
    required String userId,
    required Map<String, dynamic> registrationData,
    required Map<String, dynamic> notificationData,
  }) async {
    final eventRef = _db.collection('events').doc(eventId);
    final userRef = _db.collection('users').doc(userId);
    final registrationRef = eventRef.collection('registrations').doc(userId);
    final notifRef = _db.collection('notifications').doc(); // Auto ID

    return await _db.runTransaction((transaction) async {
      final eventDoc = await transaction.get(eventRef);
      if (!eventDoc.exists) throw Exception("Event does not exist!");

      // Check if already registered
      final regDoc = await transaction.get(registrationRef);
      if (regDoc.exists) {
        throw Exception("You are already registered for this event.");
      }

      // 1. Save registration details
      transaction.set(registrationRef, {
        ...registrationData,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment Event registrationCount
      transaction.update(eventRef, {
        'registrationCount': FieldValue.increment(1),
        // Update club stats potentially depending on denormalization strategy
      });

      // 3. Update User registered array
      transaction.update(userRef, {
        'registeredEventIds': FieldValue.arrayUnion([eventId]),
      });

      // 4. Send Confirmation Notification to User
      transaction.set(notifRef, {
        ...notificationData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Fetch all registrations for a particular event
  Future<List<Map<String, dynamic>>> getEventRegistrations(String eventId) async {
    final snapshot = await _db
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .orderBy('registeredAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(),
);

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
// Using core ClubModel but avoiding conflict

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Students ─────────────────────────────────────────────────────────────

  /// Fetch a user by ID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      aliasName: data['aliasName'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'],
      registeredEventIds: List<String>.from(data['registeredEventIds'] ?? []),
      branch: data['branch'],
      year: data['year'],
      bio: data['bio'],
    );
  }

  /// Create a new user profile document
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set({
      'email': user.email,
      'name': user.name,
      'aliasName': user.aliasName,
      'role': user.role,
      'avatarUrl': user.avatarUrl,
      'registeredEventIds': user.registeredEventIds,
      'branch': user.branch,
      'year': user.year,
      'bio': user.bio,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing user's profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ─── Clubs ────────────────────────────────────────────────────────────────

  /// Fetch a club by ID
  Future<ClubModel?> getClub(String uid) async {
    final doc = await _db.collection('clubs').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return ClubModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      logoUrl: data['logoUrl'] ?? '',
      memberCount: data['memberCount'] ?? 0,
      eventCount: data['eventCount'] ?? 0,
      facultyMentor: data['facultyMentor'] ?? '',
      totalRegistrations: data['totalRegistrations'] ?? 0,
      tagline: data['tagline'] ?? '',
      email: data['email'] ?? '',
      founded: data['founded'] ?? '',
      location: data['location'] ?? '',
    );
  }

  /// Create or update a club profile
  Future<void> updateClub(String uid, Map<String, dynamic> data) async {
    await _db.collection('clubs').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Fetch all clubs
  Future<List<ClubModel>> getAllClubs() async {
    final snapshot = await _db.collection('clubs').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ClubModel(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        category: data['category'] ?? 'Other',
        logoUrl: data['logoUrl'] ?? '',
        memberCount: data['memberCount'] ?? 0,
        eventCount: data['eventCount'] ?? 0,
        facultyMentor: data['facultyMentor'] ?? '',
        totalRegistrations: data['totalRegistrations'] ?? 0,
        tagline: data['tagline'] ?? '',
        email: data['email'] ?? '',
        founded: data['founded'] ?? '',
        location: data['location'] ?? '',
      );
    }).toList();
  }
}

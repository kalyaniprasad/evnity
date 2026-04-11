import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/alias_generator.dart';

// ── AuthService – Firebase (Email + Google) ────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // ── Detect which Firestore collection a UID belongs to ────────────────────
  /// Returns 'users', 'clubs', or null if the UID is not found in either.
  Future<String?> detectUserCollection(String uid) async {
    // Check clubs first — they are the more restricted role.
    final clubDoc = await _db.collection('clubs').doc(uid).get();
    if (clubDoc.exists) return 'clubs';

    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) return 'users';

    return null;
  }

  // ── Safety: remove duplicate entries ─────────────────────────────────────
  /// If a UID exists in BOTH collections (should never happen), this removes
  /// the entry from the collection that does NOT match [correctCollection].
  Future<void> _removeDuplicateEntry(
    String uid,
    String correctCollection,
  ) async {
    final wrongCollection = correctCollection == 'clubs' ? 'users' : 'clubs';
    final wrongDoc = await _db.collection(wrongCollection).doc(uid).get();
    if (wrongDoc.exists) {
      await _db.collection(wrongCollection).doc(uid).delete();
      print(
        'AUTH_SAFETY: Removed duplicate entry for $uid from "$wrongCollection".',
      );
    }
  }

  // ── Sign Up with Email ────────────────────────────────────────────────────
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role, // 'student' | 'club'
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Update display name
    await credential.user!.updateDisplayName(name);

    // Determine the SINGLE correct collection for this role
    final collection = role == 'club' ? 'clubs' : 'users';

    // Safety: remove any pre-existing entry in the OPPOSITE collection
    // (e.g., from a previous failed signup attempt)
    await _removeDuplicateEntry(uid, collection);

    final data = <String, dynamic>{
      'uid': uid,
      'email': email,
      'name': name,
      'aliasName': role == 'club' ? '' : AliasGenerator.generate(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (role == 'club') {
      // Every new club starts as pending — an admin must approve it.
      data['status'] = 'pending';
    }

    // Write to ONLY the correct collection
    await _db.collection(collection).doc(uid).set(data);

    // Send email verification
    await credential.user!.sendEmailVerification();

    return credential;
  }

  // ── Reload user and check email verification ─────────────────────────────
  /// Reloads the Firebase user from the server and returns whether the email
  /// is now verified. Used by the polling loop in EmailVerificationScreen.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();

    // ── CRITICAL FIX: Force token refresh ──────────────────────────────────
    // Once verified, we MUST force-refresh the ID token so that Firestore
    // security rules see the updated 'email_verified' claim immediately.
    // Without this, Firestore hits 'Permission Denied' for ~1 hour.
    if (_auth.currentUser?.emailVerified ?? false) {
      await _auth.currentUser?.getIdToken(true);
    }

    return _auth.currentUser?.emailVerified ?? false;
  }

  // ── Resend verification email ─────────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ── Sign In with Email ────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  /// [selectedRole] is only used on the very first Google sign-in (registration).
  /// On subsequent sign-ins the role is already in Firestore and is not overwritten.
  Future<UserCredential?> signInWithGoogle({String? selectedRole}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('DEBUG: Google Sign-In user cancelled.');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // Brand-new Google user — write to exactly ONE collection
        final role = selectedRole ?? 'student';
        final displayName = userCredential.user!.displayName ?? 'User';
        final collection = role == 'club' ? 'clubs' : 'users';

        // Safety: remove any duplicate from the opposite collection
        await _removeDuplicateEntry(uid, collection);

        final data = <String, dynamic>{
          'uid': uid,
          'email': userCredential.user!.email ?? '',
          'name': displayName,
          'aliasName': role == 'club' ? '' : AliasGenerator.generate(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (role == 'club') {
          data['status'] = 'pending';
        }

        await _db.collection(collection).doc(uid).set(data);
      } else {
        // Returning Google user — run safety check to fix any legacy duplicates
        final collection = await detectUserCollection(uid);
        if (collection != null) {
          await _removeDuplicateEntry(uid, collection);
        }
      }

      return userCredential;
    } catch (e) {
      print('DEBUG: Google Sign-In Exception: $e');
      rethrow;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Fetch user role from Firestore ────────────────────────────────────────
  /// Returns the role ('student' | 'club') of the given [uid].
  /// Checks 'clubs' FIRST (more restrictive), then 'users'.
  /// If the user exists in both (legacy bug), the club entry wins and the
  /// duplicate is removed.
  Future<String?> getUserRole(String uid, {String? email}) async {
    // ── 1. Check clubs collection first ───────────────────────────────────
    final clubDoc = await _db.collection('clubs').doc(uid).get();
    if (clubDoc.exists && clubDoc.data() != null) {
      if (email == null || clubDoc.data()!['email'] == email) {
        // Found in clubs — ensure no duplicate in users
        await _removeDuplicateEntry(uid, 'clubs');
        return clubDoc.data()!['role'] as String? ?? 'club';
      }
    }

    // ── 2. Fallback to users collection ───────────────────────────────────
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      if (email == null || userDoc.data()!['email'] == email) {
        return userDoc.data()!['role'] as String? ?? 'student';
      }
    }

    return null;
  }

  // ── Fetch club approval status ────────────────────────────────────────────
  /// Returns the club's status ('pending' | 'approved') from Firestore,
  /// or null if the user is not a club / document not found.
  Future<String?> getClubStatus(String uid) async {
    try {
      final doc = await _db.collection('clubs').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['status'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Check registered role for an email address ────────────────────────────
  /// Returns the stored role ('student'|'club') for [email], or null if not
  /// found / Firestore is unreachable (offline). The call is non-throwing.
  Future<String?> checkEmailRole(String email) async {
    try {
      // Check clubs first
      var query = await _db
          .collection('clubs')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['role'] as String? ?? 'club';
      }

      // Then check users
      query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['role'] as String? ?? 'student';
      }

      return null;
    } catch (_) {
      return null; // offline or error – let sign-in proceed normally
    }
  }

  // ── Friendly role-conflict message ────────────────────────────────────────
  static String roleConflictMessage(
    String registeredRole,
    String attemptedRole,
  ) {
    final reg = registeredRole == 'club' ? 'Club Organizer' : 'Student';
    final att = attemptedRole == 'club' ? 'Club Organizer' : 'Student';
    return 'This email is already registered as a $reg.\n\nPlease use the "$reg" role to sign in, or use a different email for $att access.';
  }

  // ── Map Firebase error codes → friendly messages ──────────────────────────
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ── AuthService – Firebase (Email + Google) ────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

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

    // Update display name
    await credential.user!.updateDisplayName(name);

    // Persist role + profile to Firestore
    await _db.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send email verification to the newly created user
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

      // If new user → persist role to Firestore
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final role = selectedRole ?? 'student';
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? '',
          'name': userCredential.user!.displayName ?? 'User',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
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
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  // ── Check registered role for an email address ──────────────────────────
  /// Returns the stored role ('student'|'club') for [email], or null if not
  /// found / Firestore is unreachable (offline). The call is non-throwing.
  Future<String?> checkEmailRole(String email) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first.data()['role'] as String?;
    } catch (_) {
      return null; // offline or error – let sign-in proceed normally
    }
  }

  // ── Friendly role-conflict message ───────────────────────────────────────
  static String roleConflictMessage(String registeredRole, String attemptedRole) {
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

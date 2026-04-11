import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ── User Role ─────────────────────────────────────────────────────────────────

enum UserRole { none, student, club }

// ── Firebase Auth Stream ──────────────────────────────────────────────────────

/// Streams the currently signed-in Firebase user (or null if signed out).
/// Uses idTokenChanges() so it emits on sign-in, sign-out, AND whenever the
/// ID token is refreshed (critical for picking up email_verified changes).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.idTokenChanges();
});

// ── Router Notifier ───────────────────────────────────────────────────────────

/// A [ChangeNotifier] that calls [notifyListeners] whenever Firebase auth state
/// or the user's role changes. GoRouter uses this as its [refreshListenable]
/// so that redirects re-evaluate on every auth/role transition.
///
/// Using a proper [Notifier]-backed [ChangeNotifier] (instead of a raw
/// [ValueNotifier] + [ref.listen] inside a plain Provider) guarantees the
/// subscription is alive for the full lifetime of the provider.
class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    // Listen to auth state – notifies GoRouter on sign-in / sign-out.
    ref.listen<AsyncValue<User?>>(
      firebaseUserProvider,
      (_, _) => notifyListeners(),
    );
    // Listen to role – notifies GoRouter once Firestore resolves the role.
    ref.listen<AsyncValue<String?>>(
      userRoleProvider,
      (_, _) => notifyListeners(),
    );
    // Listen to club status – notifies GoRouter on status updates.
    ref.listen<AsyncValue<String?>>(
      clubStatusProvider,
      (_, _) => notifyListeners(),
    );
  }
}

/// Provider that exposes the [RouterNotifier] instance.
/// Marked [keepAlive] so it (and its subscriptions) are never disposed.
final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  ref.keepAlive();
  return RouterNotifier(ref);
});

// ── Role Provider ─────────────────────────────────────────────────────────────

/// Fetches the user's role ('student' | 'club') from Firestore.
///
/// Watches the full [firebaseUserProvider] StreamProvider (NOT .future) so
/// this FutureProvider re-runs on every auth state change — including the
/// transition from unauthenticated → authenticated that happens right after
/// signup, and after email verification reloads the user object.
final userRoleProvider = FutureProvider<String?>((ref) async {
  // Watch the StreamProvider directly so any new User emission triggers a re-run.
  final userAsync = ref.watch(firebaseUserProvider);
  final user = userAsync.valueOrNull;
  if (user == null) return null;

  final authService = ref.read(authServiceProvider);
  return authService.getUserRole(user.uid, email: user.email);
});

// ── Club Status Provider ──────────────────────────────────────────────────────

/// Streams the club's approval status ('pending' | 'approved') from Firestore
/// in real-time. Returns null if the user is not signed in or is not a club.
///
/// IMPORTANT: Uses a synchronous [ref.watch] pattern (NOT async* + await
/// ref.watch) to avoid a critical Riverpod pitfall:
///
/// In an async* generator, when a watched [FutureProvider] (like
/// [userRoleProvider]) re-evaluates — which is common during the signup flow
/// as Firestore writes settle — Riverpod restarts the generator. This
/// restart *silently cancels* the active Firestore `.snapshots()` stream,
/// so any subsequent Firestore status updates (e.g. admin sets 'approved')
/// are never emitted to listeners.
///
/// The synchronous pattern below rebuilds deterministically: whenever
/// [firebaseUserProvider] or [userRoleProvider] changes, Riverpod disposes
/// the old stream and creates a fresh Firestore subscription automatically.
final clubStatusProvider = StreamProvider<String?>((ref) {
  // Synchronously watch auth and role — rebuilds the stream when either changes.
  final userAsync = ref.watch(firebaseUserProvider);
  final roleAsync = ref.watch(userRoleProvider);

  final user = userAsync.valueOrNull;
  final role = roleAsync.valueOrNull;

  // Not signed in, role not yet resolved from Firestore, or not a club.
  if (user == null || role == null || role != 'club') {
    return Stream.value(null);
  }

  // Real-time Firestore listener — emits the current status immediately,
  // then re-emits on every change (e.g. admin sets status to 'approved').
  return FirebaseFirestore.instance
      .collection('clubs')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data()?['status'] as String?);
});

// ── Auth Form State ───────────────────────────────────────────────────────────

class AuthFormState {
  final UserRole selectedRole;
  final bool isLoginMode;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? errorMessage;

  /// True immediately after a brand-new email/password registration succeeds.
  /// Reset to false after the caller has consumed it (navigated to verify screen).
  final bool isNewEmailRegistration;

  const AuthFormState({
    this.selectedRole = UserRole.none,
    this.isLoginMode = true,
    this.isPasswordVisible = false,
    this.isLoading = false,
    this.errorMessage,
    this.isNewEmailRegistration = false,
  });

  AuthFormState copyWith({
    UserRole? selectedRole,
    bool? isLoginMode,
    bool? isPasswordVisible,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isNewEmailRegistration,
  }) {
    return AuthFormState(
      selectedRole: selectedRole ?? this.selectedRole,
      isLoginMode: isLoginMode ?? this.isLoginMode,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isNewEmailRegistration:
          isNewEmailRegistration ?? this.isNewEmailRegistration,
    );
  }
}

// ── Auth Form Notifier ────────────────────────────────────────────────────────

class AuthFormNotifier extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void selectRole(UserRole role) {
    if (state.selectedRole == role) {
      state = state.copyWith(selectedRole: UserRole.none);
    } else {
      state = state.copyWith(selectedRole: role, clearError: true);
    }
  }

  void toggleMode() {
    state = state.copyWith(isLoginMode: !state.isLoginMode, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void setLoading(bool value) => state = state.copyWith(isLoading: value);

  void setError(String message) =>
      state = state.copyWith(errorMessage: message, isLoading: false);

  void clearError() => state = state.copyWith(clearError: true);

  /// Called by the auth screen once it has consumed the flag and navigated.
  void clearNewRegistration() =>
      state = state.copyWith(isNewEmailRegistration: false);

  // ── Submit (Email Sign Up / Sign In) ──────────────────────────────────────

  Future<void> submitForm({
    required String email,
    required String password,
    String? name,
  }) async {
    setLoading(true);

    final service = ref.read(authServiceProvider);

    try {
      if (state.isLoginMode) {
        // ── LOGIN: role is detected from Firestore — NOT from the UI ─────────
        // We do NOT require the user to have a role selected on login.
        // The router resolves the correct destination via userRoleProvider
        // + clubStatusProvider after sign-in completes.
        await service.signInWithEmail(email: email, password: password);
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          isNewEmailRegistration: false,
        );
      } else {
        // ── SIGNUP: role selection IS required ────────────────────────────
        if (state.selectedRole == UserRole.none) {
          setError('Please select your role to continue.');
          return;
        }
        final roleStr =
            state.selectedRole == UserRole.student ? 'student' : 'club';
        await service.signUpWithEmail(
          email: email,
          password: password,
          name: name ?? 'User${DateTime.now().millisecond}',
          role: roleStr,
        );
        // Signal that the UI should redirect to the verification screen.
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          isNewEmailRegistration: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      setError(AuthService.friendlyError(e));
    } catch (e) {
      setError('Something went wrong. Please try again.');
    }
  }
}

final authFormProvider = NotifierProvider<AuthFormNotifier, AuthFormState>(
  AuthFormNotifier.new,
);

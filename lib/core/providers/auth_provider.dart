import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// ── User Role ─────────────────────────────────────────────────────────────────

enum UserRole { none, student, club }

// ── Firebase Auth Stream ──────────────────────────────────────────────────────

/// Streams the currently signed-in Firebase user (or null if signed out).
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
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
/// Automatically re-runs whenever the Firebase user changes.
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(firebaseUserProvider.future);
  if (user == null) return null;

  final authService = ref.read(authServiceProvider);
  return authService.getUserRole(user.uid);
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
    // Role required for sign-up; for sign-in we need at least one selected
    // so the router knows where to redirect.
    if (state.selectedRole == UserRole.none) {
      setError('Please select your role to continue.');
      return;
    }

    setLoading(true);

    final service = ref.read(authServiceProvider);
    final roleStr = state.selectedRole == UserRole.student ? 'student' : 'club';

    try {
      if (state.isLoginMode) {
        // ── Role conflict check (email sign-in only) ────────────────────────
        final storedRole = await service.checkEmailRole(email);
        if (storedRole != null && storedRole != roleStr) {
          setError(AuthService.roleConflictMessage(storedRole, roleStr));
          return;
        }
        await service.signInWithEmail(email: email, password: password);
        state = state.copyWith(
          isLoading: false,
          clearError: true,
          isNewEmailRegistration: false,
        );
      } else {
        // ── Brand-new email registration ───────────────────────────────────
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

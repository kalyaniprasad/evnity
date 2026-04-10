import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/user_repository.dart';
import 'auth_provider.dart';
import '../repositories/notification_repository.dart';
import '../repositories/chat_repository.dart';
import '../services/push_notification_service.dart';
import '../../../core/utils/alias_generator.dart'; // Added this import

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS PROVIDER
// TODO: Replace notifier body with Supabase queries when integrating backend
// ═══════════════════════════════════════════════════════════════════════════

import '../repositories/event_repository.dart';

final studentEventProvider = StreamProvider<List<EventModel>>((ref) {
  final repo = ref.read(eventRepositoryProvider);
  return repo.streamEvents();
});

// Helper for search/filter logic since it's no longer a Notifier
class EventFilters {
  static List<EventModel> getByCategory(
    List<EventModel> events,
    String category,
  ) {
    if (category == 'All') return events;
    return events.where((e) => e.category == category).toList();
  }

  static List<EventModel> search(List<EventModel> events, String query) {
    if (query.trim().isEmpty) return events;
    final q = query.toLowerCase();
    return events
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.clubName.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q),
        )
        .toList();
  }
}

// Convenience: single event by id
final eventByIdProvider = Provider.family<EventModel?, String>((ref, id) {
  final eventsAsync = ref.watch(studentEventProvider);
  final events = eventsAsync.valueOrNull ?? [];
  try {
    return events.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

final notificationProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty) return Stream.value([]);

  final repo = ref.read(notificationRepositoryProvider);
  return repo.streamUserNotifications(user.id);
});

final unreadCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationProvider);
  final notifications = notificationsAsync.valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
});

// ═══════════════════════════════════════════════════════════════════════════
// DISCUSSION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

// discussionStreamProvider streams data based on an event ID
final discussionStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, eventId) {
      final repo = ref.watch(chatRepositoryProvider);
      return repo.streamEventMessages(eventId);
    });

// Provides an easy way to send messages
class DiscussionHelper {
  final Ref ref;
  DiscussionHelper(this.ref);

  Future<void> sendMessage(String eventId, String text) async {
    final user = ref.read(currentUserProvider);
    if (user.id.isEmpty) return;

    final repo = ref.read(chatRepositoryProvider);
    final dt = DateTime.now();
    final isPM = dt.hour >= 12;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$min ${isPM ? 'PM' : 'AM'}';

    await repo.sendMessage(
      eventId: eventId,
      senderId: user.id,
      senderAlias: user.aliasName,
      message: text,
      senderTypeStr: 'student', // Students use this provider
      formattedTime: formattedTime,
    );
  }
}

final discussionHelperProvider = Provider<DiscussionHelper>(
  (ref) => DiscussionHelper(ref),
);

// studentEventProvider is now a StreamProvider

// ═══════════════════════════════════════════════════════════════════════════
// CURRENT USER PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class CurrentUserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    final firebaseUserAsync = ref.watch(firebaseUserProvider);
    final firebaseUser = firebaseUserAsync.valueOrNull;

    if (firebaseUser == null) {
      return const UserModel(
        id: '',
        email: '',
        name: 'Guest',
        aliasName: 'Guest',
        role: 'student',
      );
    }

    // Attempt to fetch fresh data from Firestore
    _fetchUser(
      firebaseUser.uid,
      firebaseUser.email,
      firebaseUser.displayName,
      firebaseUser.photoURL,
    );

    // Initial state based on Auth token
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      aliasName: firebaseUser.displayName?.isNotEmpty == true
          ? firebaseUser.displayName!
          : (firebaseUser.email?.split('@').first ?? 'User'),
      role: 'student', // Default until fetch completes
      avatarUrl: firebaseUser.photoURL,
    );
  }

  Future<void> _fetchUser(
    String uid,
    String? email,
    String? name,
    String? photoUrl,
  ) async {
    final userRepository = ref.read(userRepositoryProvider);
    var dbUser = await userRepository.getUser(uid);
    final notifRepo = ref.read(notificationRepositoryProvider);

    if (dbUser == null) {
      // Possible race condition: auth state changed before AuthService finished writing to Firestore.
      // Wait briefly and try fetching again.
      await Future.delayed(const Duration(milliseconds: 1000));
      dbUser = await userRepository.getUser(uid);
    }

    if (dbUser != null) {
      state = dbUser;
      // Start listening for notifications once user is loaded
      PushNotificationService.startFirestoreListener(uid);
      // Ensure a profile-incomplete notification exists if needed
      _checkAndEnsureProfileNotification(dbUser, notifRepo);
    } else {
      // User doc might not exist yet if just registered via Google, create it
      final roleAsync = ref.read(userRoleProvider);
      final role = roleAsync.valueOrNull ?? 'student';

      final newUser = UserModel(
        id: uid,
        email: email ?? '',
        name: name ?? (email?.split('@').first ?? 'User'),
        aliasName: role == 'club' ? '' : AliasGenerator.generate(),
        role: role,
        avatarUrl: photoUrl,
      );
      await userRepository.createUser(newUser);
      state = newUser;
      // Start listening for notifications for newly created user
      PushNotificationService.startFirestoreListener(uid);
      // New user always has an incomplete profile
      await notifRepo.ensureProfileIncompleteNotification(
        userId: uid,
        role: role,
      );
    }
  }

  void _checkAndEnsureProfileNotification(
    UserModel user,
    NotificationRepository notifRepo,
  ) {
    final isStudent = user.role == 'student';
    final bool incomplete = isStudent
        ? ((user.branch == null || user.branch!.isEmpty) ||
              (user.year == null || user.year!.isEmpty) ||
              (user.bio == null || user.bio!.isEmpty))
        : false; // Club profile completeness is checked separately

    if (incomplete) {
      notifRepo.ensureProfileIncompleteNotification(
        userId: user.id,
        role: user.role,
      );
    } else if (isStudent) {
      // Profile is now complete — remove the reminder notification
      notifRepo.dismissProfileIncompleteNotification(user.id);
    }
  }

  void updateAlias(String newAlias) {
    state = state.copyWith(aliasName: newAlias);
  }

  void updateProfile(StudentProfileEditState editState) {
    state = state.copyWith(
      name: editState.fullName,
      aliasName: editState.aliasName,
      branch: editState.branch,
      year: editState.year,
      bio: editState.bio,
    );
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, UserModel>(
  CurrentUserNotifier.new,
);

// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

// ─── Profile Completion Check ─────────────────────────────────────────────────

/// True when the logged-in student's profile is not fully filled in.
/// Watches live so it updates the moment the user saves their profile.
final isProfileIncompleteProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty || user.role != 'student') return false;
  return (user.branch == null || user.branch!.isEmpty) ||
      (user.year == null || user.year!.isEmpty) ||
      (user.bio == null || user.bio!.isEmpty);
});

// ═══════════════════════════════════════════════════════════════════════════
// SEARCH PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void clear() {
    state = const SearchState();
  }
}

class SearchState {
  final String query;
  final String selectedCategory;

  const SearchState({this.query = '', this.selectedCategory = 'All'});

  SearchState copyWith({String? query, String? selectedCategory}) =>
      SearchState(
        query: query ?? this.query,
        selectedCategory: selectedCategory ?? this.selectedCategory,
      );
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

// Derived: filtered results
final filteredEventsProvider = Provider<List<EventModel>>((ref) {
  final searchState = ref.watch(searchProvider);
  final allEventsAsync = ref.watch(studentEventProvider);
  final allEvents = allEventsAsync.valueOrNull ?? [];

  var results = allEvents;

  if (searchState.selectedCategory != 'All') {
    results = EventFilters.getByCategory(results, searchState.selectedCategory);
  }

  if (searchState.query.trim().isNotEmpty) {
    results = EventFilters.search(results, searchState.query);
  }

  return results;
});

// Fetch all clubs from Firebase
final allClubsProvider = FutureProvider<List<ClubModel>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getAllClubs();
});

// Derived: filtered clubs (mirrors filteredEventsProvider pattern)
final filteredClubsProvider = Provider<List<ClubModel>>((ref) {
  final searchState = ref.watch(searchProvider);
  final allClubsAsync = ref.watch(allClubsProvider);
  final allClubs = allClubsAsync.valueOrNull ?? [];
  var results = List<ClubModel>.from(allClubs);

  if (searchState.selectedCategory != 'All') {
    results = results
        .where((c) => c.category == searchState.selectedCategory)
        .toList();
  }

  if (searchState.query.trim().isNotEmpty) {
    final q = searchState.query.toLowerCase();
    results = results
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.category.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();
  }

  return results;
});

// Convenience: single club by id
final clubByIdProvider = Provider.family<ClubModel?, String>((ref, id) {
  final allClubsAsync = ref.watch(allClubsProvider);
  final allClubs = allClubsAsync.valueOrNull ?? [];
  try {
    return allClubs.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT PROFILE EDIT STATE
// Isolated edit state – pre-filled from currentUserProvider, saved on demand.
// ═══════════════════════════════════════════════════════════════════════════

class StudentProfileEditState {
  final String aliasName;
  final String fullName;
  final String branch;
  final String year;
  final String bio;

  const StudentProfileEditState({
    this.aliasName = '',
    this.fullName = '',
    this.branch = '',
    this.year = '',
    this.bio = '',
  });

  StudentProfileEditState copyWith({
    String? aliasName,
    String? fullName,
    String? branch,
    String? year,
    String? bio,
  }) => StudentProfileEditState(
    aliasName: aliasName ?? this.aliasName,
    fullName: fullName ?? this.fullName,
    branch: branch ?? this.branch,
    year: year ?? this.year,
    bio: bio ?? this.bio,
  );
}

class StudentProfileEditNotifier extends Notifier<StudentProfileEditState> {
  @override
  StudentProfileEditState build() {
    // Pre-fill from the current user data.
    final user = ref.read(currentUserProvider);
    return StudentProfileEditState(
      aliasName: user.aliasName,
      fullName: user.name, // Mapping to the real name field
      branch: user.branch ?? '',
      year: user.year ?? '',
      bio: user.bio ?? '',
    );
  }

  void setAlias(String v) => state = state.copyWith(aliasName: v);
  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setBranch(String v) => state = state.copyWith(branch: v);
  void setYear(String v) => state = state.copyWith(year: v);
  void setBio(String v) => state = state.copyWith(bio: v);

  /// Commits the edit state back to currentUserProvider and saving to Firestore.
  Future<void> save() async {
    final user = ref.read(currentUserProvider);
    if (user.id.isEmpty) return;

    final repo = ref.read(userRepositoryProvider);

    final updatedData = {
      'name': state.fullName,
      'aliasName': state.aliasName,
      'branch': state.branch,
      'year': state.year,
      'bio': state.bio,
    };

    await repo.updateUser(user.id, updatedData);

    // Refresh the local State
    ref.read(currentUserProvider.notifier).updateProfile(state);

    // Dismiss the profile-completion notification if profile is now complete
    final isNowComplete =
        state.branch.isNotEmpty &&
        state.year.isNotEmpty &&
        state.bio.isNotEmpty;
    if (isNowComplete) {
      await ref
          .read(notificationRepositoryProvider)
          .dismissProfileIncompleteNotification(user.id);
    }
  }
}

final studentProfileEditProvider =
    NotifierProvider<StudentProfileEditNotifier, StudentProfileEditState>(
      StudentProfileEditNotifier.new,
    );

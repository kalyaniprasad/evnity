import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../mock_data/mock_data.dart';
import 'auth_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS PROVIDER
// TODO: Replace notifier body with Supabase queries when integrating backend
// ═══════════════════════════════════════════════════════════════════════════

class StudentEventNotifier extends Notifier<List<EventModel>> {
  @override
  List<EventModel> build() => kMockEvents;

  void toggleRegistration(String eventId) {
    state = [
      for (final event in state)
        if (event.id == eventId)
          event.copyWith(isRegistered: !event.isRegistered)
        else
          event,
    ];
  }

  List<EventModel> getByCategory(String category) {
    if (category == 'All') return state;
    return state.where((e) => e.category == category).toList();
  }

  List<EventModel> search(String query) {
    final q = query.toLowerCase();
    return state
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.clubName.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
  }

  List<EventModel> get registeredEvents =>
      state.where((e) => e.isRegistered).toList();
}

final studentEventProvider =
    NotifierProvider<StudentEventNotifier, List<EventModel>>(
        StudentEventNotifier.new);

// Convenience: single event by id
final eventByIdProvider = Provider.family<EventModel?, String>((ref, id) {
  final events = ref.watch(studentEventProvider);
  try {
    return events.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class NotificationNotifier extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() => kMockNotifications;

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<NotificationModel>>(
        NotificationNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});

// ═══════════════════════════════════════════════════════════════════════════
// DISCUSSION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

class DiscussionNotifier extends Notifier<List<MessageModel>> {
  @override
  List<MessageModel> build() => kMockMessages;

  void sendMessage(String text) {
    final newMsg = MessageModel(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'u1',
      senderAlias: 'EventExplorer45',
      message: text,
      timestamp: _formatTime(DateTime.now()),
      senderType: MessageSenderType.student,
    );
    state = [...state, newMsg];
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

final discussionProvider =
    NotifierProvider<DiscussionNotifier, List<MessageModel>>(
        DiscussionNotifier.new);

// ═══════════════════════════════════════════════════════════════════════════
// CURRENT USER PROVIDER
// FIX: Reads real identity from Firebase Auth + userRoleProvider instead of
// using static mock data. Falls back gracefully while async data resolves.
// ═══════════════════════════════════════════════════════════════════════════

class CurrentUserNotifier extends Notifier<UserModel> {
  @override
  UserModel build() {
    // FIX: Pull the live Firebase user and resolved role from Riverpod.
    // ref.watch() means this rebuild whenever auth state changes (e.g. logout).
    final firebaseUserAsync = ref.watch(firebaseUserProvider);
    final roleAsync = ref.watch(userRoleProvider);

    final User? firebaseUser = firebaseUserAsync.valueOrNull;
    final String? role = roleAsync.valueOrNull;

    // If signed out or still loading, return an empty/default model.
    if (firebaseUser == null) {
      return UserModel(
        id: '',
        email: '',
        aliasName: 'Guest',
        role: 'student',
      );
    }

    // Build UserModel from real Firebase data.
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      // Use displayName if available; otherwise derive from email prefix.
      aliasName: firebaseUser.displayName?.isNotEmpty == true
          ? firebaseUser.displayName!
          : (firebaseUser.email?.split('@').first ?? 'User'),
      role: role ?? 'student', // default to 'student' until Firestore responds
      avatarUrl: firebaseUser.photoURL,
    );
  }

  void updateAlias(String newAlias) {
    state = state.copyWith(aliasName: newAlias);
  }
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, UserModel>(CurrentUserNotifier.new);

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

  const SearchState({
    this.query = '',
    this.selectedCategory = 'All',
  });

  SearchState copyWith({String? query, String? selectedCategory}) => SearchState(
        query: query ?? this.query,
        selectedCategory: selectedCategory ?? this.selectedCategory,
      );
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

// Derived: filtered results
final filteredEventsProvider = Provider<List<EventModel>>((ref) {
  final searchState = ref.watch(searchProvider);
  final allEvents = ref.watch(studentEventProvider);

  var results = allEvents;

  if (searchState.selectedCategory != 'All') {
    results = results
        .where((e) => e.category == searchState.selectedCategory)
        .toList();
  }

  if (searchState.query.trim().isNotEmpty) {
    final q = searchState.query.toLowerCase();
    results = results
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.clubName.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q))
        .toList();
  }

  return results;
});

// Derived: filtered clubs (mirrors filteredEventsProvider pattern)
final filteredClubsProvider = Provider<List<ClubModel>>((ref) {
  final searchState = ref.watch(searchProvider);
  var results = List<ClubModel>.from(kMockClubs);

  if (searchState.selectedCategory != 'All') {
    results = results
        .where((c) => c.category == searchState.selectedCategory)
        .toList();
  }

  if (searchState.query.trim().isNotEmpty) {
    final q = searchState.query.toLowerCase();
    results = results
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  return results;
});

// Convenience: single club by id
final clubByIdProvider = Provider.family<ClubModel?, String>((ref, id) {
  try {
    return kMockClubs.firstWhere((c) => c.id == id);
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
    this.year = 'First Year',
    this.bio = '',
  });

  StudentProfileEditState copyWith({
    String? aliasName,
    String? fullName,
    String? branch,
    String? year,
    String? bio,
  }) =>
      StudentProfileEditState(
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
      fullName: user.aliasName,
      branch: 'Computer Science', // Mock default — replace with real field when backend ready
      year: 'Third Year',
      bio: 'Passionate about technology and innovation.',
    );
  }

  void setAlias(String v) => state = state.copyWith(aliasName: v);
  void setFullName(String v) => state = state.copyWith(fullName: v);
  void setBranch(String v) => state = state.copyWith(branch: v);
  void setYear(String v) => state = state.copyWith(year: v);
  void setBio(String v) => state = state.copyWith(bio: v);

  /// Commits the edit state back to currentUserProvider.
  void save() {
    ref.read(currentUserProvider.notifier).updateAlias(state.aliasName);
  }
}

final studentProfileEditProvider =
    NotifierProvider<StudentProfileEditNotifier, StudentProfileEditState>(
        StudentProfileEditNotifier.new);


import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../../core/models/message_model.dart';
import '../../../core/providers/student_providers.dart'; // To get chatRepositoryProvider


// ═══════════════════════════════════════════════════════════════════════════════
// CLUB EVENTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

final clubEventsProvider = StreamProvider<List<ClubEvent>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty) return Stream.value([]);

  final repo = ref.watch(eventRepositoryProvider);
  return repo.streamClubEvents(user.id);
});

// ═══════════════════════════════════════════════════════════════════════════════
// CLUB STATS PROVIDER  (derived — no backend needed)
// ═══════════════════════════════════════════════════════════════════════════════

final clubStatsProvider = Provider<ClubStats>((ref) {
  final eventsAsync = ref.watch(clubEventsProvider);
  final events = eventsAsync.valueOrNull ?? [];

  return ClubStats(
    activeEvents: events.length, // Let's just consider all as active for now
    totalRegistrations: events.fold(0, (sum, e) => sum + e.registrationCount),
    unreadMessages: 0, // Mock for now
    totalEvents: events.length,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// DISCUSSION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

// clubDiscussionStreamProvider streams messages from a particular event
// Since ClubChat represents organizers viewing the same chat room, we reuse the core ChatRepository stream
final clubDiscussionStreamProvider = StreamProvider.family<List<MessageModel>, String>((ref, eventId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamEventMessages(eventId);
});

// Helper for clubs to send messages
class ClubDiscussionHelper {
  final Ref ref;
  ClubDiscussionHelper(this.ref);

  Future<void> sendMessage(String eventId, String text) async {
    final user = ref.read(currentUserProvider);
    if (user.id.isEmpty) return; // Should ideally be club check

    // As a simple shortcut for now, an organizer alias is used
    final aliasName = '${user.aliasName} Organizer';
    final repo = ref.read(chatRepositoryProvider);
    final dt = DateTime.now();
    final isPM = dt.hour >= 12;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$min ${isPM ? 'PM' : 'AM'}';

    await repo.sendMessage(
      eventId: eventId,
      senderId: user.id,
      senderAlias: aliasName,
      message: text,
      senderTypeStr: 'organizer', // Clubs use this provider
      formattedTime: formattedTime,
    );
  }
}

final clubDiscussionHelperProvider = Provider<ClubDiscussionHelper>((ref) => ClubDiscussionHelper(ref));

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE EVENT FORM PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class CreateEventState {
  final String title;
  final String category;
  final String venue;
  final String description;
  final String date;
  final String time;
  final File? posterFile;

  const CreateEventState({
    this.title = '',
    this.category = 'Technical',
    this.venue = '',
    this.description = '',
    this.date = '',
    this.time = '',
    this.posterFile,
  });

  bool get isValid =>
      title.trim().isNotEmpty &&
      venue.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      date.isNotEmpty &&
      time.isNotEmpty &&
      posterFile != null;

  CreateEventState copyWith({
    String? title,
    String? category,
    String? venue,
    String? description,
    String? date,
    String? time,
    File? posterFile,
  }) =>
      CreateEventState(
        title: title ?? this.title,
        category: category ?? this.category,
        venue: venue ?? this.venue,
        description: description ?? this.description,
        date: date ?? this.date,
        time: time ?? this.time,
        posterFile: posterFile ?? this.posterFile,
      );
}

class CreateEventNotifier extends Notifier<CreateEventState> {
  @override
  CreateEventState build() => const CreateEventState();

  void setTitle(String v) => state = state.copyWith(title: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setVenue(String v) => state = state.copyWith(venue: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setDate(String v) => state = state.copyWith(date: v);
  void setTime(String v) => state = state.copyWith(time: v);
  void setPoster(File? file) => state = state.copyWith(posterFile: file);
  void reset() => state = const CreateEventState();
}

final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(
        CreateEventNotifier.new);

// ═══════════════════════════════════════════════════════════════════════════════
// MANAGE EVENTS TAB FILTER
// ═══════════════════════════════════════════════════════════════════════════════

final manageTabProvider = StateProvider<int>((ref) => 0);

// ═══════════════════════════════════════════════════════════════════════════════
// CLUB PROFILE MODEL & PROVIDER
// Holds editable club identity data. Backed by mock data for now.
// ═══════════════════════════════════════════════════════════════════════════════

class ClubProfileModel {
  final String name;
  final String tagline;
  final String description;
  final String category;
  final String facultyMentor;
  final String email;
  final String founded;
  final String location;

  const ClubProfileModel({
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.facultyMentor,
    required this.email,
    required this.founded,
    required this.location,
  });

  ClubProfileModel copyWith({
    String? name,
    String? tagline,
    String? description,
    String? category,
    String? facultyMentor,
    String? email,
    String? founded,
    String? location,
  }) =>
      ClubProfileModel(
        name: name ?? this.name,
        tagline: tagline ?? this.tagline,
        description: description ?? this.description,
        category: category ?? this.category,
        facultyMentor: facultyMentor ?? this.facultyMentor,
        email: email ?? this.email,
        founded: founded ?? this.founded,
        location: location ?? this.location,
      );

  /// Returns short initials (up to 2 chars) for the logo placeholder.
  String get initials {
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 2).toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

class ClubProfileNotifier extends Notifier<ClubProfileModel> {
  bool _initialized = false;

  @override
  ClubProfileModel build() {
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_fetchProfile);
    }
    return const ClubProfileModel(
      name: '',
      tagline: '',
      description: '',
      category: 'Technical',
      facultyMentor: '',
      email: '',
      founded: '',
      location: '',
    );
  }

  Future<void> _fetchProfile() async {
    final user = ref.read(currentUserProvider);
    if (user.id.isEmpty) return;

    final repo = ref.read(userRepositoryProvider);
    final club = await repo.getClub(user.id);
    if (club != null) {
      state = ClubProfileModel(
        name: club.name.isNotEmpty ? club.name : state.name,
        tagline: club.tagline.isNotEmpty ? club.tagline : state.tagline,
        description: club.description.isNotEmpty ? club.description : state.description,
        category: club.category.isNotEmpty ? club.category : state.category,
        facultyMentor: club.facultyMentor.isNotEmpty ? club.facultyMentor : state.facultyMentor,
        email: club.email.isNotEmpty ? club.email : state.email,
        founded: club.founded.isNotEmpty ? club.founded : state.founded,
        location: club.location.isNotEmpty ? club.location : state.location,
      );
    }
  }

  void update(ClubProfileModel updated) => state = updated;

  void setName(String v) => state = state.copyWith(name: v);
  void setTagline(String v) => state = state.copyWith(tagline: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setCategory(String v) => state = state.copyWith(category: v);
  void setFacultyMentor(String v) => state = state.copyWith(facultyMentor: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setFounded(String v) => state = state.copyWith(founded: v);
  void setLocation(String v) => state = state.copyWith(location: v);
}

final clubProfileProvider =
    NotifierProvider<ClubProfileNotifier, ClubProfileModel>(
        ClubProfileNotifier.new);


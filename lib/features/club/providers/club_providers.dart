import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CLUB EVENTS PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class ClubEventsNotifier extends Notifier<List<ClubEvent>> {
  @override
  List<ClubEvent> build() => kMockClubEvents;

  void addEvent(ClubEvent event) => state = [...state, event];

  void deleteEvent(String id) =>
      state = state.where((e) => e.id != id).toList();

  void toggleStatus(String id) {
    state = [
      for (final e in state)
        if (e.id == id)
          e.copyWith(
            status: e.status == EventStatus.published
                ? EventStatus.draft
                : EventStatus.published,
          )
        else
          e,
    ];
  }

  ClubEvent? byId(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final clubEventsProvider =
    NotifierProvider<ClubEventsNotifier, List<ClubEvent>>(
        ClubEventsNotifier.new);

// ═══════════════════════════════════════════════════════════════════════════════
// CLUB STATS PROVIDER  (derived — no backend needed)
// ═══════════════════════════════════════════════════════════════════════════════

final clubStatsProvider = Provider<ClubStats>((ref) {
  final events = ref.watch(clubEventsProvider);
  return ClubStats(
    activeEvents:
        events.where((e) => e.status == EventStatus.published).length,
    totalRegistrations:
        events.fold(0, (sum, e) => sum + e.registrationCount),
    unreadMessages: events.fold(0, (sum, e) => sum + e.messageCount),
    totalEvents: events.length,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// DISCUSSION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

class ClubDiscussionNotifier extends Notifier<List<ClubMessage>> {
  @override
  List<ClubMessage> build() => kMockClubMessages;

  void sendMessage(String text) {
    final now = DateTime.now();
    final h = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    state = [
      ...state,
      ClubMessage(
        id: 'cm_${now.millisecondsSinceEpoch}',
        senderAlias: 'CodeCraft Organizer',
        message: text,
        timestamp: '$h:$m $period',
        senderType: ClubMessageSender.organizer,
      ),
    ];
  }
}

final clubDiscussionProvider =
    NotifierProvider<ClubDiscussionNotifier, List<ClubMessage>>(
        ClubDiscussionNotifier.new);

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
  final bool posterSelected;

  const CreateEventState({
    this.title = '',
    this.category = 'Technical',
    this.venue = '',
    this.description = '',
    this.date = '',
    this.time = '',
    this.posterSelected = false,
  });

  bool get isValid =>
      title.trim().isNotEmpty &&
      venue.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      date.isNotEmpty &&
      time.isNotEmpty;

  CreateEventState copyWith({
    String? title,
    String? category,
    String? venue,
    String? description,
    String? date,
    String? time,
    bool? posterSelected,
  }) =>
      CreateEventState(
        title: title ?? this.title,
        category: category ?? this.category,
        venue: venue ?? this.venue,
        description: description ?? this.description,
        date: date ?? this.date,
        time: time ?? this.time,
        posterSelected: posterSelected ?? this.posterSelected,
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
  void togglePoster() =>
      state = state.copyWith(posterSelected: !state.posterSelected);
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
  @override
  ClubProfileModel build() => const ClubProfileModel(
        name: 'CodeCraft Club',
        tagline: 'Build. Innovate. Inspire.',
        description:
            'CodeCraft Club is the premier technical club on campus. We organize hackathons, workshops, and seminars to build the next generation of developers. We believe in learning by doing and creating impact through code.',
        category: 'Technical',
        facultyMentor: 'Dr. Rajesh Sharma',
        email: 'codecraft@college.edu',
        founded: '2019',
        location: 'Main Campus, Block D',
      );

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


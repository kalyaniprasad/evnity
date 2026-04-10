import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../../core/models/message_model.dart';
import '../../../core/providers/student_providers.dart'; // To get chatRepositoryProvider
import '../../../core/repositories/notification_repository.dart';
import '../../../core/repositories/event_repository.dart';
import '../models/registration_field_model.dart';

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
final clubDiscussionStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, eventId) {
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

final clubDiscussionHelperProvider = Provider<ClubDiscussionHelper>(
  (ref) => ClubDiscussionHelper(ref),
);

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
  final List<RegistrationFieldModel> formFields;

  const CreateEventState({
    this.title = '',
    this.category = 'Technical',
    this.venue = '',
    this.description = '',
    this.date = '',
    this.time = '',
    this.posterFile,
    this.formFields = const [],
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
    List<RegistrationFieldModel>? formFields,
  }) => CreateEventState(
    title: title ?? this.title,
    category: category ?? this.category,
    venue: venue ?? this.venue,
    description: description ?? this.description,
    date: date ?? this.date,
    time: time ?? this.time,
    posterFile: posterFile ?? this.posterFile,
    formFields: formFields ?? this.formFields,
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

  void addFormField({FormFieldType? type}) {
    state = state.copyWith(
      formFields: [
        ...state.formFields,
        RegistrationFieldModel.create().copyWith(type: type),
      ],
    );
  }

  void updateFormField(String id, RegistrationFieldModel updated) {
    state = state.copyWith(
      formFields: state.formFields.map((f) => f.id == id ? updated : f).toList(),
    );
  }

  void removeFormField(String id) {
    state = state.copyWith(
      formFields: state.formFields.where((f) => f.id != id).toList(),
    );
  }

  void reorderFormFields(int oldIndex, int newIndex) {
    final fields = List<RegistrationFieldModel>.from(state.formFields);
    final item = fields.removeAt(oldIndex);
    fields.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = state.copyWith(formFields: fields);
  }

  void setFormFields(List<RegistrationFieldModel> fields) {
    state = state.copyWith(formFields: fields);
  }

  void reset() => state = const CreateEventState();
}

final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(
      CreateEventNotifier.new,
    );

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
  }) => ClubProfileModel(
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
    if (name.trim().isEmpty) return 'CL';
    final words = name.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'CL';
    if (words.length == 1) {
      return words[0].length >= 2
          ? words[0].substring(0, 2).toUpperCase()
          : words[0].toUpperCase();
    }
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
    final notifRepo = ref.read(_clubNotifRepoProvider);
    final club = await repo.getClub(user.id);
    if (club != null) {
      state = ClubProfileModel(
        name: club.name.isNotEmpty ? club.name : state.name,
        tagline: club.tagline.isNotEmpty ? club.tagline : state.tagline,
        description: club.description.isNotEmpty
            ? club.description
            : state.description,
        category: club.category.isNotEmpty ? club.category : state.category,
        facultyMentor: club.facultyMentor.isNotEmpty
            ? club.facultyMentor
            : state.facultyMentor,
        email: club.email.isNotEmpty ? club.email : state.email,
        founded: club.founded.isNotEmpty ? club.founded : state.founded,
        location: club.location.isNotEmpty ? club.location : state.location,
      );

      // Check if club profile is incomplete after loading
      final incomplete =
          state.tagline.isEmpty ||
          state.description.isEmpty ||
          state.facultyMentor.isEmpty ||
          state.location.isEmpty;

      if (incomplete) {
        notifRepo.ensureProfileIncompleteNotification(
          userId: user.id,
          role: 'club',
        );
      } else {
        // If it was complete, ensure any old Firebase notification is deleted
        notifRepo.dismissProfileIncompleteNotification(user.id);
      }
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
      ClubProfileNotifier.new,
    );

// Internal helper – avoids circular dependency
final _clubNotifRepoProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

/// True when the club's profile is not fully filled in.
/// Watches live so it auto-updates when the profile is saved.
final isClubProfileIncompleteProvider = Provider<bool>((ref) {
  final profile = ref.watch(clubProfileProvider);
  final user = ref.watch(currentUserProvider);
  if (user.id.isEmpty || user.role != 'club') return false;
  return profile.tagline.isEmpty ||
      profile.description.isEmpty ||
      profile.facultyMentor.isEmpty ||
      profile.location.isEmpty;
});

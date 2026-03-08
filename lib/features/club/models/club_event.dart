enum EventStatus { published, draft }

class ClubEvent {
  final String id;
  final String title;
  final String category;
  final String date;
  final String time;
  final String venue;
  final String posterUrl;
  final String description;
  final EventStatus status;
  final int registrationCount;
  final int messageCount;

  const ClubEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.time,
    required this.venue,
    required this.posterUrl,
    required this.description,
    required this.status,
    required this.registrationCount,
    required this.messageCount,
  });

  ClubEvent copyWith({
    String? title,
    String? category,
    String? date,
    String? time,
    String? venue,
    String? description,
    EventStatus? status,
  }) =>
      ClubEvent(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        date: date ?? this.date,
        time: time ?? this.time,
        venue: venue ?? this.venue,
        posterUrl: posterUrl,
        description: description ?? this.description,
        status: status ?? this.status,
        registrationCount: registrationCount,
        messageCount: messageCount,
      );
}

class EventModel {
  final String id;
  final String title;
  final String clubName;
  final String clubLogoUrl;
  final String date;
  final String time;
  final String venue;
  final String category;
  final String posterUrl;
  final String description;
  final int registrationCount;
  final bool isRegistered;

  const EventModel({
    required this.id,
    required this.title,
    required this.clubName,
    required this.clubLogoUrl,
    required this.date,
    required this.time,
    required this.venue,
    required this.category,
    required this.posterUrl,
    required this.description,
    required this.registrationCount,
    this.isRegistered = false,
  });

  EventModel copyWith({bool? isRegistered}) => EventModel(
        id: id,
        title: title,
        clubName: clubName,
        clubLogoUrl: clubLogoUrl,
        date: date,
        time: time,
        venue: venue,
        category: category,
        posterUrl: posterUrl,
        description: description,
        registrationCount: registrationCount,
        isRegistered: isRegistered ?? this.isRegistered,
      );
}

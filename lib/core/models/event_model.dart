import 'package:intl/intl.dart';

enum EventTimingStatus { upcoming, live, completed }

class EventModel {
  final String id;
  final String title;
  final String hostClubId;
  final String clubName;
  final String organizerName; // New field for redundancy/user requirement
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
    required this.hostClubId,
    required this.clubName,
    required this.organizerName,
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
        hostClubId: hostClubId,
        clubName: clubName,
        organizerName: organizerName,
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

extension EventStatusExtension on EventModel {
  EventTimingStatus get currentStatus {
    try {
      // 1. Clean date (handles "Sat, 15 Mar 2025" or "15 Mar 2025")
      final cleanDate = date.contains(',') ? date.split(', ').last.trim() : date.trim();
      
      // 2. Split time string (assumes format "10:00 AM - 02:00 PM")
      final timeParts = time.split('-');
      if (timeParts.length < 2) return EventTimingStatus.upcoming; // Fallback
      
      final startTimeStr = timeParts[0].trim();
      final endTimeStr = timeParts[1].trim();

      // 3. Parse date and merge with times
      final DateFormat formatter = DateFormat('dd MMM yyyy h:mm a');
      final DateTime startDateTime = formatter.parse('$cleanDate $startTimeStr');
      final DateTime endDateTime = formatter.parse('$cleanDate $endTimeStr');
      final DateTime now = DateTime.now();

      // 4. Determine status
      if (now.isBefore(startDateTime)) {
        return EventTimingStatus.upcoming;
      } else if (now.isAfter(endDateTime)) {
        return EventTimingStatus.completed;
      } else {
        return EventTimingStatus.live;
      }
    } catch (e) {
      return EventTimingStatus.upcoming; // Fallback entirely 
    }
  }
}

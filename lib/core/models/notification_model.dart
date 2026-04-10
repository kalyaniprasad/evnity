enum NotificationType {
  eventUpdate,
  reminder,
  announcement,
  registration,
  profileIncomplete,
}

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final NotificationType type;
  final bool isRead;
  final String? eventId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.eventId,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    title: title,
    description: description,
    timestamp: timestamp,
    type: type,
    isRead: isRead ?? this.isRead,
    eventId: eventId,
  );
}

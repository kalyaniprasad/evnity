enum ClubMessageSender { student, organizer }

class ClubMessage {
  final String id;
  final String senderAlias;
  final String message;
  final String timestamp;
  final ClubMessageSender senderType;

  const ClubMessage({
    required this.id,
    required this.senderAlias,
    required this.message,
    required this.timestamp,
    required this.senderType,
  });
}

enum MessageSenderType { student, organizer }

class MessageModel {
  final String id;
  final String senderId;
  final String senderAlias;
  final String message;
  final String timestamp;
  final MessageSenderType senderType;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderAlias,
    required this.message,
    required this.timestamp,
    required this.senderType,
  });
}

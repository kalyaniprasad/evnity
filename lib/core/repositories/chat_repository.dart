import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class ChatRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Stream messages for a specific event discussion
  /// Returns standard MessageModel mostly suitable for student view
  Stream<List<MessageModel>> streamEventMessages(String eventId) {
    return _db
        .ref('event_chats/$eventId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <MessageModel>[];

      final messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
      final messagesList = messagesMap.entries.map((entry) {
        final data = entry.value as Map<dynamic, dynamic>;

        // Parse Sender Type
        MessageSenderType type;
        if (data['senderType'] == 'organizer') {
          type = MessageSenderType.organizer;
        } else {
          type = MessageSenderType.student;
        }

        return MessageModel(
          id: entry.key.toString(),
          senderId: data['senderId'] ?? '',
          senderAlias: data['senderAlias'] ?? 'Anonymous',
          message: data['message'] ?? '',
          timestamp: data['timestamp'] ?? '', // Store formatted string for simplicity
          senderType: type,
        );
      }).toList();

      // Sort by explicitly parsing timestamp or rely on insertion order based on push keys
      messagesList.sort((a, b) => a.id.compareTo(b.id)); // Assuming push keys which are chronologically sortable
      return messagesList;
    });
  }

  /// Sends a message to the event's chat room
  Future<void> sendMessage({
    required String eventId,
    required String senderId,
    required String senderAlias,
    required String message,
    required String senderTypeStr, // 'student' or 'organizer'
    required String formattedTime,
  }) async {
    final chatRef = _db.ref('event_chats/$eventId/messages').push();

    await chatRef.set({
      'senderId': senderId,
      'senderAlias': senderAlias,
      'message': message,
      'senderType': senderTypeStr,
      'timestamp': formattedTime,
      'serverTimestamp': ServerValue.timestamp,
    });
  }
}

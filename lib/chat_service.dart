import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';

class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Send a message to a specific channel
  Future<void> sendMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final messageId = const Uuid().v4();
    final message = ChatMessage(
      id: messageId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: DateTime.now(),
    );

    await _database
        .ref('channel_messages/$channelId')
        .push()
        .set(message.toRealtimeDatabase());
  }

  // Get messages for a specific channel
  Stream<List<ChatMessage>> getChannelMessages(String channelId) {
    return _database
        .ref('channel_messages/$channelId')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final Map<dynamic, dynamic>? messagesMap = 
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (messagesMap == null) return <ChatMessage>[];

      // Convert and sort messages by timestamp
      return messagesMap.entries
        .map((entry) => ChatMessage.fromRealtimeDatabase(
          Map<String, dynamic>.from(entry.value)
        ))
        .toList()
        // Sort in descending order (most recent first)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }
}
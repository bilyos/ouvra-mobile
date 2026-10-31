/// Un message dans une conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentByMe,
    required this.time,
    this.imageUrl,
  });

  final String id;
  final String text;
  final bool sentByMe;
  final DateTime time;
  final String? imageUrl;

  /// [myUserId] permet de déduire `sentByMe` depuis `senderId` (fiable en WS).
  factory ChatMessage.fromJson(Map<String, dynamic> json, String? myUserId) {
    return ChatMessage(
      id: json['id'].toString(),
      text: (json['text'] as String?) ?? '',
      sentByMe: myUserId != null
          ? json['senderId']?.toString() == myUserId
          : (json['sentByMe'] as bool?) ?? false,
      time: DateTime.tryParse(json['sentAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// Aperçu d'une conversation dans la liste des discussions.
class Conversation {
  const Conversation({
    required this.id,
    required this.providerId,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    this.isOnline = false,
    this.messages = const [],
  });

  final String id;
  final String providerId;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isOnline;
  final List<ChatMessage> messages;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final other = (json['other'] as Map<String, dynamic>?) ?? const {};
    return Conversation(
      id: json['id'].toString(),
      providerId: other['id']?.toString() ?? '',
      name: (other['name'] as String?) ?? 'Conversation',
      avatarUrl: (other['avatarUrl'] as String?) ?? '',
      lastMessage: (json['lastMessage'] as String?) ?? '',
      time: DateTime.tryParse(json['lastMessageAt']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

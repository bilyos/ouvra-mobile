import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mock_conversations.dart';
import '../domain/chat_models.dart';

part 'chat_controller.g.dart';

/// Liste des conversations (mockée). À remplacer par WebSocket + API.
@riverpod
class ChatController extends _$ChatController {
  @override
  List<Conversation> build() => List.of(kMockConversations);

  Conversation? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Ouvre (ou crée) la conversation avec un prestataire et renvoie son id.
  String startConversationWith({
    required String providerId,
    required String name,
    required String avatarUrl,
    bool isOnline = false,
  }) {
    for (final c in state) {
      if (c.providerId == providerId) return c.id;
    }
    final id = 'c${state.length + 1}';
    state = [
      Conversation(
        id: id,
        providerId: providerId,
        name: name,
        avatarUrl: avatarUrl,
        lastMessage: 'Nouvelle conversation',
        time: DateTime.now(),
        unreadCount: 0,
        isOnline: isOnline,
        messages: const [],
      ),
      ...state,
    ];
    return id;
  }

  /// Envoie un message dans une conversation et simule une réponse.
  void sendMessage(String conversationId, String text) {
    if (text.trim().isEmpty) return;
    state = [
      for (final c in state)
        if (c.id == conversationId)
          _appendMessage(
            c,
            ChatMessage(
              id: 'm${c.messages.length + 1}',
              text: text.trim(),
              sentByMe: true,
              time: DateTime.now(),
            ),
          )
        else
          c,
    ];
  }

  Conversation _appendMessage(Conversation c, ChatMessage m) => Conversation(
        id: c.id,
        providerId: c.providerId,
        name: c.name,
        avatarUrl: c.avatarUrl,
        lastMessage: m.text.isEmpty ? '📷 Photo' : m.text,
        time: m.time,
        unreadCount: 0,
        isOnline: c.isOnline,
        messages: [...c.messages, m],
      );
}

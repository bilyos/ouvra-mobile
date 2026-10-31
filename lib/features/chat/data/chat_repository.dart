import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/chat_models.dart';

/// Accès à l'API du chat (REST). Le temps réel passe par [StompService].
class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<Conversation>> conversations() async {
    final res = await _dio.get('/conversations');
    return (res.data as List)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> start(String providerId) async {
    final res = await _dio.post('/conversations', data: {'providerId': providerId});
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> messages(String conversationId, String? myUserId) async {
    final res = await _dio.get('/conversations/$conversationId/messages');
    return (res.data as List)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, myUserId))
        .toList();
  }

  Future<ChatMessage> send(String conversationId, String text,
      {String? imageUrl}) async {
    final data = <String, dynamic>{'text': text};
    if (imageUrl != null) data['imageUrl'] = imageUrl;
    final res =
        await _dio.post('/conversations/$conversationId/messages', data: data);
    // La réponse porte sentByMe=true (relatif à l'expéditeur).
    return ChatMessage.fromJson(res.data as Map<String, dynamic>, null);
  }

  Future<int> unreadCount() async {
    final res = await _dio.get('/conversations/unread-count');
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

final conversationsProvider =
    FutureProvider.autoDispose<List<Conversation>>((ref) async {
  return ref.watch(chatRepositoryProvider).conversations();
});

final chatUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(chatRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});

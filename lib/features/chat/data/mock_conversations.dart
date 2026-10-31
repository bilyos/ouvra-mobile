import '../domain/chat_models.dart';

/// Conversations mockées. Remplacé par WebSocket + historique API.
final List<Conversation> kMockConversations = [
  Conversation(
    id: 'c1',
    providerId: 'p1',
    name: 'Jean-Paul Mbarga',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    lastMessage: "D'accord, je passe demain à 9h 👍",
    time: DateTime.now().subtract(const Duration(minutes: 5)),
    unreadCount: 2,
    isOnline: true,
    messages: [
      ChatMessage(id: 'm1', text: 'Bonjour, j\'ai une fuite sous l\'évier.', sentByMe: true, time: DateTime.now().subtract(const Duration(minutes: 30))),
      ChatMessage(id: 'm2', text: 'Bonjour ! Pouvez-vous m\'envoyer une photo ?', sentByMe: false, time: DateTime.now().subtract(const Duration(minutes: 28))),
      ChatMessage(id: 'm3', text: '', sentByMe: true, time: DateTime.now().subtract(const Duration(minutes: 25)), imageUrl: 'https://picsum.photos/seed/leak/400'),
      ChatMessage(id: 'm4', text: 'Je vois. C\'est un joint à changer, 5000 FCFA main d\'œuvre.', sentByMe: false, time: DateTime.now().subtract(const Duration(minutes: 20))),
      ChatMessage(id: 'm5', text: 'Parfait, vous pouvez passer demain ?', sentByMe: true, time: DateTime.now().subtract(const Duration(minutes: 8))),
      ChatMessage(id: 'm6', text: "D'accord, je passe demain à 9h 👍", sentByMe: false, time: DateTime.now().subtract(const Duration(minutes: 5))),
    ],
  ),
  Conversation(
    id: 'c2',
    providerId: 'p2',
    name: 'Christelle Ngo',
    avatarUrl: 'https://i.pravatar.cc/150?img=45',
    lastMessage: 'Merci beaucoup, à bientôt !',
    time: DateTime.now().subtract(const Duration(hours: 3)),
    unreadCount: 0,
    isOnline: true,
    messages: [
      ChatMessage(id: 'm1', text: 'Bonjour, disponible samedi pour des tresses ?', sentByMe: true, time: DateTime.now().subtract(const Duration(hours: 4))),
      ChatMessage(id: 'm2', text: 'Oui ! Samedi 14h ça vous va ?', sentByMe: false, time: DateTime.now().subtract(const Duration(hours: 3, minutes: 30))),
      ChatMessage(id: 'm3', text: 'Parfait 🙏', sentByMe: true, time: DateTime.now().subtract(const Duration(hours: 3, minutes: 10))),
      ChatMessage(id: 'm4', text: 'Merci beaucoup, à bientôt !', sentByMe: false, time: DateTime.now().subtract(const Duration(hours: 3))),
    ],
  ),
  Conversation(
    id: 'c3',
    providerId: 'p4',
    name: 'Fatima Bello',
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
    lastMessage: 'Je vous confirme pour lundi matin.',
    time: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 0,
    isOnline: false,
    messages: [
      ChatMessage(id: 'm1', text: 'Bonjour, besoin d\'un ménage complet lundi.', sentByMe: true, time: DateTime.now().subtract(const Duration(days: 1, hours: 1))),
      ChatMessage(id: 'm2', text: 'Je vous confirme pour lundi matin.', sentByMe: false, time: DateTime.now().subtract(const Duration(days: 1))),
    ],
  ),
];

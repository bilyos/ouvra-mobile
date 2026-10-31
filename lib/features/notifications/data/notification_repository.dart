import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Notification affichée dans l'app.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.refType,
    this.refId,
  });

  final String id;

  /// MESSAGE, REVIEW, FAVORITE, SYSTEM, REQUEST, QUOTE.
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  /// Objet visé (« booking », « conversation »…) et son identifiant.
  final String? refType;
  final String? refId;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'].toString(),
        type: (j['type'] as String?) ?? 'SYSTEM',
        title: (j['title'] as String?) ?? '',
        body: (j['body'] as String?) ?? '',
        read: (j['read'] as bool?) ?? false,
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
        refType: j['refType'] as String?,
        refId: j['refId'] as String?,
      );
}

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> list() async {
    final res = await _dio.get('/notifications', queryParameters: {'size': 50});
    final content = (res.data['content'] as List?) ?? const [];
    return content
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) => _dio.put('/notifications/$id/read');

  Future<void> markAllRead() => _dio.put('/notifications/read-all');
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).list();
});

final notificationUnreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  try {
    return await ref.watch(notificationRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});

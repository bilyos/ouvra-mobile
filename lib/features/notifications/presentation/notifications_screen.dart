import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/format.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAll(WidgetRef ref) async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(notificationsProvider);
    ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> _open(
      BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.read) {
      ref.read(notificationRepositoryProvider).markRead(n.id).then((_) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(notificationUnreadCountProvider);
      }).ignore();
    }
    final id = n.refId;
    if (id == null) return;
    switch (n.refType) {
      case 'booking' || 'urgent_booking':
        context.push(AppRoutes.booking(id));
      case 'conversation':
        context.push(AppRoutes.chat(id));
      case 'provider':
        context.push(AppRoutes.providerDetail(id));
      case 'job_request':
        context.push(AppRoutes.request(id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final hasUnread =
        async.valueOrNull?.any((n) => !n.read) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () => _markAll(ref),
              child: const Text('Tout lire'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(notificationsProvider.future),
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ListView(children: [
            ErrorState(
              message: apiErrorMessage(e),
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
          ]),
          data: (items) => items.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    title: 'Aucune notification',
                    message:
                        'Les réponses des prestataires, les paiements et les messages s\'afficheront ici.',
                  ),
                ])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(indent: AppSpacing.gutter + 36),
                  itemBuilder: (context, i) => _NotificationRow(
                    n: items[i],
                    onTap: () => _open(context, ref, items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  IconData get _icon => switch (n.type) {
        'MESSAGE' => Icons.chat_bubble_outline_rounded,
        'REVIEW' => Icons.star_outline_rounded,
        'FAVORITE' => Icons.favorite_border_rounded,
        'REQUEST' || 'QUOTE' => Icons.request_quote_outlined,
        _ => n.refType == 'booking' || n.refType == 'urgent_booking'
            ? Icons.event_note_outlined
            : Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(_icon,
                  size: 22, color: n.read ? p.subtle : p.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight:
                                    n.read ? FontWeight.w500 : FontWeight.w700)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(formatListTime(n.createdAt),
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(n.body,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: p.mutedForeground),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (!n.read) ...[
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  height: 8,
                  width: 8,
                  decoration:
                      BoxDecoration(color: p.primary, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

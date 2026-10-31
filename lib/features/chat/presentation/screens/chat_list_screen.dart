import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_models.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(conversationsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
              child: Semantics(
                header: true,
                child: Text('Messages', style: theme.textTheme.displaySmall),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.refresh(conversationsProvider.future),
                child: async.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ListView(children: [
                    ErrorState(
                      message: apiErrorMessage(e),
                      onRetry: () => ref.invalidate(conversationsProvider),
                    ),
                  ]),
                  data: (conversations) => conversations.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 60),
                          EmptyState(
                            title: 'Aucune conversation',
                            message:
                                'Écrivez à un prestataire depuis son profil pour lui poser vos questions. Votre numéro reste privé.',
                            actionLabel: 'Trouver un prestataire',
                            onAction: () => context.go(AppRoutes.search),
                          ),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => const Divider(
                              indent: AppSpacing.gutter + 52 + AppSpacing.md),
                          itemBuilder: (_, i) =>
                              _ConversationTile(conversation: conversations[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final c = conversation;
    final unread = c.unreadCount > 0;
    return InkWell(
      onTap: () => context.push(AppRoutes.chat(c.id),
          extra: {'name': c.name, 'avatarUrl': c.avatarUrl}),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          children: [
            AppAvatar(
                name: c.name, url: c.avatarUrl, size: 52, online: c.isOnline),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(formatListTime(c.time),
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: unread ? p.primary : null,
                              fontWeight: unread ? FontWeight.w700 : null)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage.isEmpty ? 'Photo' : c.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: unread ? p.ink : p.mutedForeground),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: p.primary,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('${c.unreadCount}',
                              style: TextStyle(
                                  color: p.onPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

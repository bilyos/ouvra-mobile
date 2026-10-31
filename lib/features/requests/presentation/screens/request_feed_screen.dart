import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';
import '../widgets/request_photos.dart';

/// Fil du prestataire : les problèmes publiés près de lui dans son métier.
class RequestFeedScreen extends ConsumerStatefulWidget {
  const RequestFeedScreen({super.key});

  @override
  ConsumerState<RequestFeedScreen> createState() => _RequestFeedScreenState();
}

class _RequestFeedScreenState extends ConsumerState<RequestFeedScreen> {
  RequestTiming? _filter;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(requestFeedProvider(_filter));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes autour de vous'),
        actions: [
          IconButton(
            tooltip: 'Mes devis',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push(AppRoutes.myQuotes),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.xs, AppSpacing.gutter, AppSpacing.sm),
            child: SegmentedChoice<RequestTiming?>(
              values: const [null, RequestTiming.now],
              selected: _filter,
              label: (t) => t == null ? 'Toutes' : 'Urgentes',
              onChanged: (t) => setState(() => _filter = t),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.refresh(requestFeedProvider(_filter).future),
              child: async.when(
                loading: () => const LoadingView(),
                error: (e, _) => ListView(children: [
                  ErrorState(
                      message: apiErrorMessage(e),
                      onRetry: () => ref.invalidate(requestFeedProvider(_filter))),
                ]),
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(children: [
                      const SizedBox(height: 60),
                      EmptyState(
                        title: _filter == null
                            ? 'Aucune demande pour l\'instant'
                            : 'Aucune urgence en ce moment',
                        message:
                            'Vous serez prévenu dès qu\'un client publie un problème de votre métier près de vous. Restez en ligne pour être parmi les premiers.',
                      ),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.sm, AppSpacing.gutter, AppSpacing.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _FeedCard(
                      request: list[i],
                      onTap: () async {
                        await context.push(AppRoutes.request(list[i].id));
                        ref.invalidate(requestFeedProvider(_filter));
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une demande dans le fil : la photo d'abord, c'est elle qui fait chiffrer.
class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.request, required this.onTap});

  final JobRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final r = request;
    final urgent = r.timing == RequestTiming.now;
    final quoted = r.myQuote != null &&
        (r.myQuote!.status == QuoteStatus.sent ||
            r.myQuote!.status == QuoteStatus.accepted);

    return Material(
      color: p.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.photos.isNotEmpty)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                  child: RequestGallery(photos: r.photos, height: 168),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (urgent) ...[
                        Icon(Icons.bolt_rounded, size: 16, color: p.danger),
                        Text('Urgent  ',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: p.danger)),
                      ],
                      Expanded(
                        child: Text(
                          [r.place, ?kmText(r.distanceKm)].join(' · '),
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(agoText(r.createdAt),
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (r.description != null && r.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.description!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: p.mutedForeground),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (r.voiceUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.graphic_eq_rounded,
                            size: 18, color: p.primary),
                        const SizedBox(width: 6),
                        Text(
                            'Note vocale${r.voiceSeconds == null ? '' : ' de ${r.voiceSeconds} s'}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: p.primary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      AppAvatar(
                          name: r.clientName, url: r.clientAvatarUrl, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          [
                            r.clientName,
                            if (r.budgetMax != null)
                              'budget ${formatFcfa(r.budgetMax!)}',
                          ].join(' · '),
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (quoted)
                        Text('Devis envoyé',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: p.success))
                      else
                        Text('${r.quoteCount}/${r.maxQuotes} devis',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color:
                                    r.isFull ? p.subtle : p.mutedForeground)),
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

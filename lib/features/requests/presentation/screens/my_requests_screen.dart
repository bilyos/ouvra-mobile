import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../data/request_repository.dart';
import '../../domain/job_request.dart';
import '../request_format.dart';

/// Les problèmes publiés par le client et les devis reçus.
class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes demandes'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle demande',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.newRequest),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(myRequestsProvider.future),
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ListView(children: [
            ErrorState(
                message: apiErrorMessage(e),
                onRetry: () => ref.invalidate(myRequestsProvider)),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 60),
                EmptyState(
                  title: 'Une fuite, une panne, un meuble à monter ?',
                  message:
                      'Prenez une photo ou laissez une note vocale. Les prestataires du quartier vous répondent avec un prix.',
                  actionLabel: 'Publier ma première demande',
                  onAction: () => context.push(AppRoutes.newRequest),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(
                  indent: AppSpacing.gutter + 64 + AppSpacing.md),
              itemBuilder: (_, i) => RequestRow(
                request: list[i],
                onTap: () => context.push(AppRoutes.request(list[i].id)),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Ligne de demande : vignette, titre, état, temps restant.
class RequestRow extends StatelessWidget {
  const RequestRow({super.key, required this.request, required this.onTap});

  final JobRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = request;
    final (label, tone) = requestStatus(r);
    final left = r.isOpen ? remainingText(r.expiresAt) : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          children: [
            RequestThumb(request: r, size: 64),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    [
                      categoryLabel(r.categoryId),
                      left ?? 'publiée ${agoText(r.createdAt)}',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  StatusLabel(label: label, tone: tone),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded, color: context.palette.subtle),
          ],
        ),
      ),
    );
  }
}

/// Vignette d'une demande : sa première photo, sinon l'icône du métier.
class RequestThumb extends StatelessWidget {
  const RequestThumb({super.key, required this.request, this.size = 56});

  final JobRequest request;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (request.photos.isNotEmpty) {
      final photo = request.photos.first;
      return NetImage(
        url: photo.thumbnailUrl ?? photo.url,
        width: size,
        height: size,
        radius: AppSpacing.radiusSm,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(
        request.voiceUrl != null
            ? Icons.graphic_eq_rounded
            : categoryIcon(request.categoryId),
        color: p.mutedForeground,
      ),
    );
  }
}

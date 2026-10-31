import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/state_views.dart';
import '../../../chat/data/chat_repository.dart';
import '../../data/provider_repository.dart';
import '../../domain/service_provider.dart';

class ProviderDetailScreen extends ConsumerStatefulWidget {
  const ProviderDetailScreen({super.key, required this.providerId});

  final String providerId;

  @override
  ConsumerState<ProviderDetailScreen> createState() =>
      _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> {
  bool _opening = false;

  Future<void> _contact(ServiceProvider p) async {
    setState(() => _opening = true);
    try {
      final conv = await ref.read(chatRepositoryProvider).start(p.id);
      if (mounted) {
        context.push(AppRoutes.chat(conv.id),
            extra: {'name': p.name, 'avatarUrl': p.avatarUrl});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerAsync = ref.watch(providerDetailProvider(widget.providerId));

    return providerAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: apiErrorMessage(e),
          onRetry: () =>
              ref.invalidate(providerDetailProvider(widget.providerId)),
        ),
      ),
      data: (provider) => Scaffold(
        appBar: AppBar(),
        body: _Body(provider: provider),
        bottomNavigationBar: _BottomBar(
          opening: _opening,
          onMessage: () => _contact(provider),
          onBook: () =>
              context.push(AppRoutes.bookProvider(widget.providerId)),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final distance = formatDistance(provider.distanceKm);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        // Identité
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.profession,
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      provider.city.isEmpty
                          ? provider.name
                          : '${provider.name}, ${provider.city}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: p.mutedForeground),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 16, color: p.primary),
                        const SizedBox(width: 4),
                        Text('Identité vérifiée',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: p.primary)),
                        if (provider.isOnline) ...[
                          const SizedBox(width: AppSpacing.md),
                          Text('En ligne',
                              style: theme.textTheme.labelMedium
                                  ?.copyWith(color: p.success)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppAvatar(
                  name: provider.name, url: provider.avatarUrl, size: 72),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Les trois faits qui décident
        Padding(
          padding: AppSpacing.screen,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.symmetric(
                  horizontal: BorderSide(color: p.border, width: 0.5)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Fact(
                    value: provider.reviewCount == 0
                        ? 'Nouveau'
                        : provider.rating
                            .toStringAsFixed(1)
                            .replaceAll('.', ','),
                    label: provider.reviewCount == 0
                        ? 'pas encore d\'avis'
                        : '${provider.reviewCount} avis',
                  ),
                  VerticalDivider(color: p.border, width: 1, thickness: 0.5),
                  _Fact(
                    value: formatFcfa(provider.startingPrice),
                    label: 'prix de départ',
                  ),
                  if (distance.isNotEmpty) ...[
                    VerticalDivider(color: p.border, width: 1, thickness: 0.5),
                    _Fact(value: distance, label: 'de chez vous'),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!provider.isAvailable)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
            child: Text(
              'Occupé en ce moment : il peut répondre plus tard que d\'habitude.',
              style: theme.textTheme.bodyMedium?.copyWith(color: p.warning),
            ),
          ),
        if (provider.bio.isNotEmpty) ...[
          const SectionHeader(
            title: 'À propos',
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
            child: Text(provider.bio, style: theme.textTheme.bodyLarge),
          ),
        ],
        if (provider.portfolio.isNotEmpty) ...[
          const SectionHeader(
            title: 'Réalisations',
            padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
          ),
          SizedBox(
            height: 136,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
              scrollDirection: Axis.horizontal,
              itemCount: provider.portfolio.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => NetImage(
                url: provider.portfolio[i],
                width: 160,
                height: 124,
                radius: AppSpacing.radiusSm,
              ),
            ),
          ),
        ],
        SectionHeader(
          title: provider.reviewCount == 0
              ? 'Avis'
              : 'Avis (${provider.reviewCount})',
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.xl, AppSpacing.gutter, 0),
        ),
        if (provider.reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, 0),
            child: Text(
              'Pas encore d\'avis. Les clients notent après chaque travail payé via Ouvra.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: p.mutedForeground),
            ),
          )
        else
          for (final r in provider.reviews) _ReviewTile(review: r),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = review.daysAgo;
    final when = days == 0
        ? 'aujourd\'hui'
        : days == 1
            ? 'hier'
            : 'il y a $days jours';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.authorName,
                    style: theme.textTheme.titleSmall),
              ),
              RatingStars(rating: review.rating, size: 13),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Text(when, style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.opening,
    required this.onMessage,
    required this.onBook,
  });

  final bool opening;
  final VoidCallback onMessage;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 14, color: p.mutedForeground),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Votre paiement reste bloqué jusqu\'à la fin du travail.',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Écrire',
                      icon: Icons.chat_bubble_outline_rounded,
                      variant: AppButtonVariant.tonal,
                      loading: opening,
                      onPressed: onMessage,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: AppButton(label: 'Réserver', onPressed: onBook),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

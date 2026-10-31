import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../domain/service_provider.dart';

/// Prestataire dans une liste : une ligne, pas une carte. Les lignes sont
/// séparées par un filet posé par la liste ([ProviderCard.divider]).
class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.provider, required this.onTap});

  final ServiceProvider provider;
  final VoidCallback onTap;

  /// Filet aligné sur le texte, à placer entre deux lignes.
  static const Widget divider =
      Divider(indent: AppSpacing.gutter + 56 + AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final distance = formatDistance(provider.distanceKm);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(
              name: provider.name,
              url: provider.avatarUrl,
              size: 56,
              online: provider.isOnline,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(provider.profession,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (!provider.isAvailable) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text('Occupé',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: p.warning)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(provider.name,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: p.mutedForeground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded, size: 15, color: p.primary,
                          semanticLabel: 'Profil vérifié'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingStars(
                          rating: provider.rating,
                          reviewCount: provider.reviewCount),
                      if (distance.isNotEmpty || provider.city.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            distance.isNotEmpty ? distance : provider.city,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text('dès ${formatFcfa(provider.startingPrice)}',
                          style: theme.textTheme.labelMedium),
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

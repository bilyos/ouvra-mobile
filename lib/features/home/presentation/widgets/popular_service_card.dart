import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/utils/format.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/net_image.dart';
import '../../../../shared/widgets/rating_stars.dart';
import '../../../providers/domain/service_provider.dart';

/// Prestataire mis en avant : photo d'un travail, puis le texte en dessous.
/// Rien n'est posé sur la photo.
class PopularServiceCard extends StatelessWidget {
  const PopularServiceCard({
    super.key,
    required this.provider,
    required this.onTap,
  });

  static const double width = 220;

  final ServiceProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final photo = provider.portfolio.isNotEmpty ? provider.portfolio.first : null;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                width: width,
                child: photo != null
                    ? NetImage(
                        url: photo,
                        width: width,
                        height: 140,
                        radius: AppSpacing.radiusMd,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.paper,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Center(
                          child: AppAvatar(
                              name: provider.name,
                              url: provider.avatarUrl,
                              size: 64),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(provider.profession,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                provider.city.isEmpty
                    ? provider.name
                    : '${provider.name}, ${provider.city}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  RatingStars(
                      rating: provider.rating,
                      reviewCount: provider.reviewCount),
                  const Spacer(),
                  Text('dès ${formatFcfa(provider.startingPrice)}',
                      style: theme.textTheme.labelMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

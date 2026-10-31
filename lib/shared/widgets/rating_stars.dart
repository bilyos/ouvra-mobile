import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Note compacte : une étoile, la note à la française, le nombre d'avis.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
  });

  final double rating;
  final int? reviewCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final value = rating.toStringAsFixed(1).replaceAll('.', ',');
    final count = reviewCount;
    // Sans avis, une note de 5 serait trompeuse.
    if (count == 0) {
      return Text('Nouveau',
          style: theme.textTheme.labelMedium
              ?.copyWith(fontSize: size, color: p.primary));
    }
    return Semantics(
      label: count == null
          ? 'Note $value sur 5'
          : 'Note $value sur 5, $count avis',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: size + 2, color: AppColors.sun500),
            const SizedBox(width: 2),
            Text(value,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontSize: size, color: p.ink)),
            if (count != null) ...[
              const SizedBox(width: 3),
              Text('($count)',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: size - 1)),
            ],
          ],
        ),
      ),
    );
  }
}

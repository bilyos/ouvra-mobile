import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/service_category.dart';

/// Métier : pastille ronde neutre avec l'icône, libellé dessous.
/// Une seule couleur pour tous les métiers ; la sélection passe au vert forêt.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.width = 76,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: selected ? p.primary : p.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon,
                        size: 24, color: selected ? p.onPrimary : p.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? p.primary : p.ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Faux champ de recherche de l'accueil : ouvre l'onglet Recherche.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Rechercher un métier ou un prestataire',
      child: Material(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, size: 22, color: p.mutedForeground),
                const SizedBox(width: AppSpacing.sm + 2),
                ExcludeSemantics(
                  child: Text('Plombier, électricien, ménage…',
                      style:
                          theme.textTheme.bodyLarge?.copyWith(color: p.subtle)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Pastille de choix : fond neutre, forêt une fois choisie. Même largeur dans
/// les deux états (pas de coche qui ferait bouger les voisines).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final fg = selected ? p.onPrimary : p.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.primary : p.muted,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 40,
            padding: EdgeInsets.only(
                left: icon == null ? 14 : 12, right: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 18, color: selected ? p.onPrimary : p.mutedForeground),
                  const SizedBox(width: AppSpacing.xs + 2),
                ],
                Text(label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontSize: 14, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

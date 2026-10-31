import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppButtonVariant {
  /// Jaune taxi : l'action principale de l'écran, une seule à la fois.
  primary,

  /// Vert forêt : action forte mais secondaire (« Contacter » à côté de « Réserver »).
  secondary,

  /// Fond neutre : actions d'appoint.
  tonal,

  /// Texte seul.
  plain,

  /// Action destructrice ou de signalement.
  destructive,
}

/// Bouton Ouvra : rectangle aux coins de 12 pt, à plat, sans ombre.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;

  /// Hauteur réduite (40 pt) pour les boutons dans une ligne de liste.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg) = switch (variant) {
      AppButtonVariant.primary => (p.accent, p.onAccent),
      AppButtonVariant.secondary => (p.primary, p.onPrimary),
      AppButtonVariant.tonal => (p.muted, p.ink),
      AppButtonVariant.plain => (Colors.transparent, p.primary),
      AppButtonVariant.destructive => (p.dangerSoft, p.danger),
    };

    final height = compact ? 40.0 : AppSpacing.control;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: enabled ? fg : p.subtle,
          fontSize: compact ? 15 : 16,
        );

    final child = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 18 : 20, color: style?.color),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(label,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    final button = Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled || variant == AppButtonVariant.plain ? bg : p.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

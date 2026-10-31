import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_button.dart';

/// État vide : dit ce qui manque et propose quoi faire. Pas d'illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Version en ligne, alignée à gauche, pour l'intérieur d'une page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = compact ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = compact ? TextAlign.start : TextAlign.center;
    final content = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Text(title, style: theme.textTheme.titleMedium, textAlign: textAlign),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(message!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: context.palette.mutedForeground),
                  textAlign: textAlign),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.tonal,
              expanded: false,
              compact: true,
            ),
          ],
        ],
      ),
    );
    return compact ? content : Center(child: content);
  }
}

/// Erreur réseau : message de l'API et bouton pour réessayer.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry, this.compact = false});

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'Chargement impossible',
      message: message,
      actionLabel: onRetry == null ? null : 'Réessayer',
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Indicateur de chargement discret.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.padding = AppSpacing.xxl});

  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

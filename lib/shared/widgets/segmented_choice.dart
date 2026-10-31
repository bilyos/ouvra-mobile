import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Contrôle segmenté : choix exclusif entre deux à quatre options courtes.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.muted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                selected: v == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == selected ? p.background : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: v == selected
                          ? Border.all(color: p.border, width: 0.5)
                          : null,
                    ),
                    child: Text(label(v),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 14,
                            color: v == selected ? p.ink : p.mutedForeground)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

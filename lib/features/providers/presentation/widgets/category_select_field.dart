import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../home/data/mock_categories.dart';

/// Valeur spéciale du menu pour « Autre » (catégorie libre).
const String kOtherCategory = 'autre';

/// Choix du métier : un champ qui ouvre la liste des métiers dans une feuille,
/// avec une option « Autre » qui révèle un champ libre.
class CategorySelectField extends StatelessWidget {
  const CategorySelectField({
    super.key,
    required this.value,
    required this.customController,
    required this.onChanged,
  });

  /// Id de catégorie sélectionné, ou [kOtherCategory], ou null.
  final String? value;
  final TextEditingController customController;
  final ValueChanged<String?> onChanged;

  String? get _label {
    if (value == null) return null;
    if (value == kOtherCategory) return 'Autre métier';
    for (final c in kMockCategories) {
      if (c.id == value) return c.label;
    }
    return value;
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategorySheet(selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final label = _label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Métier',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: p.mutedForeground)),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: 'Métier : ${label ?? 'non choisi'}',
          child: Material(
            color: p.muted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: () => _open(context),
              child: Container(
                height: AppSpacing.control,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label ?? 'Choisir un métier',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: label == null ? p.subtle : p.ink),
                      ),
                    ),
                    Icon(Icons.unfold_more_rounded,
                        size: 20, color: p.mutedForeground),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (value == kOtherCategory) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Précisez votre métier',
            hint: 'Réparation de téléphones',
            controller: customController,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ requis.' : null,
          ),
        ],
      ],
    );
  }
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final items = [
      for (final c in kMockCategories) (c.id, c.label, c.icon),
      (kOtherCategory, 'Autre métier', Icons.more_horiz_rounded),
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.sm),
            child: Text('Votre métier', style: theme.textTheme.titleLarge),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(indent: 58),
              itemBuilder: (context, i) {
                final (id, label, icon) = items[i];
                final isSel = id == selected;
                return ListTile(
                  leading: Icon(icon, color: p.mutedForeground),
                  title: Text(label),
                  trailing: isSel
                      ? Icon(Icons.check_rounded, color: p.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

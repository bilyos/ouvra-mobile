
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'category_select_field.dart';
import 'photo_picker_grid.dart';

export 'photo_picker_grid.dart';

/// Champs de l'activité prestataire, partagés par l'inscription et par
/// « Devenir prestataire ». À placer dans un `Form`.
class ProviderActivityFields extends StatelessWidget {
  const ProviderActivityFields({
    super.key,
    required this.categoryId,
    required this.onCategoryChanged,
    required this.customCategory,
    required this.title,
    required this.description,
    required this.price,
    required this.city,
    required this.availability,
  });

  final String? categoryId;
  final ValueChanged<String?> onCategoryChanged;
  final TextEditingController customCategory;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController city;
  final TextEditingController availability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Champ requis.' : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Votre activité', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text('Ces informations apparaissent sur votre profil public.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.palette.mutedForeground)),
        const SizedBox(height: AppSpacing.xl),
        CategorySelectField(
          value: categoryId,
          customController: customCategory,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Intitulé du métier',
          hint: 'Plombier, dépannage rapide',
          controller: title,
          textInputAction: TextInputAction.next,
          validator: required,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Description et conditions',
          hint: 'Vos services, vos quartiers, vos frais de déplacement…',
          controller: description,
          maxLines: 5,
          validator: (v) => (v == null || v.trim().length < 10)
              ? 'Écrivez au moins une phrase.'
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Prix de départ (FCFA)',
                hint: '5000',
                controller: price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: (v) => (int.tryParse(v?.trim() ?? '') == null)
                    ? 'Montant requis.'
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Ville',
                hint: 'Douala',
                controller: city,
                textInputAction: TextInputAction.next,
                validator: required,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Disponibilités',
          hint: 'Lundi au samedi, 8 h à 18 h',
          controller: availability,
          textInputAction: TextInputAction.done,
          validator: required,
        ),
      ],
    );
  }
}

/// Étape « réalisations » : texte d'aide et grille de photos.
class RealizationsFields extends StatelessWidget {
  const RealizationsFields({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Uint8List> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vos réalisations', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Des photos de vos travaux rassurent les clients. Vous pourrez en ajouter plus tard.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: context.palette.mutedForeground),
        ),
        const SizedBox(height: AppSpacing.lg),
        PhotoPickerGrid(photos: photos, onAdd: onAdd, onRemove: onRemove),
      ],
    );
  }
}

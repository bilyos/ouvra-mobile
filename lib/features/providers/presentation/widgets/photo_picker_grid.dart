import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Grille de photos de réalisations : une case d'ajout puis les vignettes.
class PhotoPickerGrid extends StatelessWidget {
  const PhotoPickerGrid({
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
    final p = context.palette;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        Material(
          color: p.muted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, color: p.primary),
                const SizedBox(height: AppSpacing.xs),
                Text('Ajouter',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: p.primary)),
              ],
            ),
          ),
        ),
        for (var i = 0; i < photos.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.memory(photos[i], fit: BoxFit.cover, cacheWidth: 300),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'Retirer la photo',
                  onPressed: () => onRemove(i),
                  icon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Color(0x99000000), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Barre de progression d'un formulaire en plusieurs étapes.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Étape ${step + 1} sur $total',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: (step + 1) / total),
          duration: const Duration(milliseconds: 250),
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 3,
            color: p.primary,
            backgroundColor: p.muted,
          ),
        ),
      ),
    );
  }
}

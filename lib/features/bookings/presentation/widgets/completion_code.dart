import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum CodePlateSize { regular, large }

/// Le code de fin de travail, présenté comme une plaque de taxi jaune :
/// c'est l'objet que le client montre au prestataire, il doit se lire de loin.
class CompletionCodePlate extends StatelessWidget {
  const CompletionCodePlate({
    super.key,
    required this.code,
    this.size = CodePlateSize.regular,
  });

  final String code;
  final CodePlateSize size;

  @override
  Widget build(BuildContext context) {
    final large = size == CodePlateSize.large;
    final digit = large ? 52.0 : 40.0;
    return Semantics(
      label: 'Code de fin de travail : ${code.split('').join(' ')}',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.all(large ? 8 : 6),
          decoration: BoxDecoration(
            color: AppColors.sun400,
            borderRadius: BorderRadius.circular(large ? 16 : 12),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: large ? 22 : 16, vertical: large ? 10 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(large ? 10 : 8),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Text(
              code.split('').join(' '),
              style: AppTypography.display(TextStyle(
                fontSize: digit,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: AppColors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
            ),
          ),
        ),
      ),
    );
  }
}

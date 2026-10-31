import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Le symbole Ouvra : un écrou vu de face, qui se lit aussi comme le « o »
/// d'ouvra. Le disque jaune au centre reprend le voyant du taxi libre.
/// Dessiné en vectoriel : aucun fichier à télécharger.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32, this.inverse = false});

  final double size;

  /// Version blanche pour les fonds vert foncé.
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Ouvra',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _NutPainter(
          body: inverse ? Colors.white : p.primary,
          light: AppColors.sun400,
        ),
      ),
    );
  }
}

/// Symbole + mot-symbole en minuscules.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 28, this.inverse = false});

  /// Taille du symbole ; le texte suit.
  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: size, inverse: inverse),
        SizedBox(width: size * 0.28),
        ExcludeSemantics(
          child: Text(
            'ouvra',
            style: AppTypography.display(TextStyle(
              fontSize: size * 0.72,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -size * 0.032,
              color: inverse ? Colors.white : p.ink,
            )),
          ),
        ),
      ],
    );
  }
}

class _NutPainter extends CustomPainter {
  const _NutPainter({required this.body, required this.light});

  final Color body;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);
    final nut = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(11.57, 3.56)
      ..quadraticBezierTo(16, 1, 20.43, 3.56)
      ..lineTo(24.56, 5.94)
      ..quadraticBezierTo(28.99, 8.5, 28.99, 13.62)
      ..lineTo(28.99, 18.38)
      ..quadraticBezierTo(28.99, 23.5, 24.56, 26.06)
      ..lineTo(20.43, 28.44)
      ..quadraticBezierTo(16, 31, 11.57, 28.44)
      ..lineTo(7.44, 26.06)
      ..quadraticBezierTo(3.01, 23.5, 3.01, 18.38)
      ..lineTo(3.01, 13.62)
      ..quadraticBezierTo(3.01, 8.5, 7.44, 5.94)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(16, 16), radius: 6.4));
    canvas.drawPath(nut, Paint()..color = body);
    canvas.drawCircle(const Offset(16, 16), 4.1, Paint()..color = light);
  }

  @override
  bool shouldRepaint(_NutPainter old) => old.body != body || old.light != light;
}

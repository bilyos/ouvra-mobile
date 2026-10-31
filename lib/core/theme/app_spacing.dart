import 'package:flutter/widgets.dart';

/// Grille de 4 pt. Les marges latérales des écrans sont de 20 pt, comme sur iOS.
abstract final class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double gutter = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Rayons : peu nombreux et liés à la taille de l'objet.
  /// Puces, vignettes, petites images.
  static const double radiusSm = 8;

  /// Boutons, champs, photos.
  static const double radiusMd = 12;

  /// Feuilles modales, grands blocs.
  static const double radiusLg = 20;

  /// Hauteur des boutons et des champs : cible tactile confortable.
  static const double control = 52;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: gutter);
}

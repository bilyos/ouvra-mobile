import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie : **Bricolage Grotesque** pour les titres (le caractère de la
/// marque, serré et franc), **Figtree** pour tout le reste (lisible en petit
/// corps sur des écrans modestes).
///
/// Échelle (pt) : 32 · 26 · 22 · 18 pour les titres, 16 · 15 · 13 · 12 pour le texte.
abstract final class AppTypography {
  AppTypography._();

  static TextStyle display(TextStyle base) =>
      GoogleFonts.bricolageGrotesque(textStyle: base);

  static TextTheme textTheme(Color ink, Color muted) {
    TextStyle head(double size, double height, FontWeight w, double tracking) =>
        GoogleFonts.bricolageGrotesque(
          fontSize: size,
          height: height,
          fontWeight: w,
          letterSpacing: tracking,
          color: ink,
        );

    TextStyle body(double size, double height, FontWeight w,
            {Color? color, double tracking = 0}) =>
        GoogleFonts.figtree(
          fontSize: size,
          height: height,
          fontWeight: w,
          letterSpacing: tracking,
          color: color ?? ink,
        );

    return TextTheme(
      // Grand titre d'écran (accueil, onglets).
      displaySmall: head(32, 1.1, FontWeight.w700, -0.9),
      // Titre d'écran secondaire.
      headlineMedium: head(26, 1.15, FontWeight.w700, -0.6),
      // Titre de section importante, montant.
      headlineSmall: head(22, 1.2, FontWeight.w700, -0.4),
      // Titre de section, barre d'app.
      titleLarge: head(18, 1.25, FontWeight.w700, -0.2),
      // Titre de ligne de liste.
      titleMedium: body(16, 1.3, FontWeight.w600),
      titleSmall: body(15, 1.3, FontWeight.w600),
      bodyLarge: body(16, 1.5, FontWeight.w400),
      bodyMedium: body(15, 1.45, FontWeight.w400),
      // Texte secondaire.
      bodySmall: body(13, 1.4, FontWeight.w400, color: muted),
      labelLarge: body(16, 1.2, FontWeight.w600),
      labelMedium: body(13, 1.2, FontWeight.w600),
      labelSmall: body(12, 1.2, FontWeight.w500, color: muted),
    );
  }
}

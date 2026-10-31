import 'package:flutter/material.dart';

/// Palette Ouvra — reprise telle quelle des tokens du site web.
///
/// forêt  : le vert profond de la marque, réservé à la structure et à la confiance
/// taxi   : le jaune des taxis de Douala, réservé à l'action principale d'un écran
/// argile : le rouge des urgences et des erreurs
/// neutres: gris légèrement verdis, pour que le papier et l'encre restent de la même famille
abstract final class AppColors {
  AppColors._();

  // Forêt (brand-*)
  static const Color brand50 = Color(0xFFEEF6F1);
  static const Color brand100 = Color(0xFFD6EADF);
  static const Color brand200 = Color(0xFFAED4C0);
  static const Color brand300 = Color(0xFF7DB89C);
  static const Color brand400 = Color(0xFF4B9877);
  static const Color brand500 = Color(0xFF267C5A);
  static const Color brand600 = Color(0xFF176848);
  static const Color brand700 = Color(0xFF12553B);
  static const Color brand800 = Color(0xFF0F4431);
  static const Color brand900 = Color(0xFF0C3727);
  static const Color brand950 = Color(0xFF061F16);

  // Taxi (sun-*)
  static const Color sun50 = Color(0xFFFFFBEA);
  static const Color sun100 = Color(0xFFFFF2C2);
  static const Color sun200 = Color(0xFFFFE489);
  static const Color sun300 = Color(0xFFFFD447);
  static const Color sun400 = Color(0xFFFCC419);
  static const Color sun500 = Color(0xFFF0AB05);
  static const Color sun600 = Color(0xFFCF8602);
  static const Color sun700 = Color(0xFFA46006);
  static const Color sun800 = Color(0xFF864B0C);

  // Argile (red-*)
  static const Color clay50 = Color(0xFFFDF3F0);
  static const Color clay100 = Color(0xFFFBE2DA);
  static const Color clay400 = Color(0xFFE26B4E);
  static const Color clay500 = Color(0xFFCF4A2C);
  static const Color clay600 = Color(0xFFB23A20);
  static const Color clay950 = Color(0xFF35100A);

  // Neutres
  static const Color gray50 = Color(0xFFF6F7F5);
  static const Color gray100 = Color(0xFFEDEFEB);
  static const Color gray200 = Color(0xFFDDE1DB);
  static const Color gray300 = Color(0xFFC4CAC2);
  static const Color gray400 = Color(0xFF949C92);
  static const Color gray500 = Color(0xFF6B7469);
  static const Color gray600 = Color(0xFF535B52);
  static const Color gray800 = Color(0xFF262C27);
  static const Color gray900 = Color(0xFF171C18);

  static const Color ink = Color(0xFF142019);
}

/// Couleurs sémantiques résolues pour le thème courant.
/// S'obtiennent avec `context.palette`.
@immutable
class OuvraPalette extends ThemeExtension<OuvraPalette> {
  const OuvraPalette({
    required this.background,
    required this.paper,
    required this.muted,
    required this.mutedForeground,
    required this.subtle,
    required this.border,
    required this.ink,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.success,
  });

  /// Fond des écrans.
  final Color background;

  /// Fond des listes groupées et des zones secondaires.
  final Color paper;

  /// Remplissage des champs, puces et boutons tonals.
  final Color muted;

  /// Texte secondaire (contraste AA sur [background]).
  final Color mutedForeground;

  /// Texte tertiaire : horodatages, mentions.
  final Color subtle;

  /// Filets et contours.
  final Color border;

  /// Texte principal.
  final Color ink;

  /// Forêt : structure, liens, sélection.
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  /// Taxi : l'action principale de l'écran, jamais plus d'une à la fois.
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  final Color danger;
  final Color dangerSoft;
  final Color warning;
  final Color success;

  static const light = OuvraPalette(
    background: Colors.white,
    paper: AppColors.gray50,
    muted: AppColors.gray100,
    mutedForeground: Color(0xFF5C655B),
    subtle: AppColors.gray500,
    border: AppColors.gray200,
    ink: AppColors.ink,
    primary: AppColors.brand700,
    onPrimary: Colors.white,
    primarySoft: AppColors.brand50,
    accent: AppColors.sun400,
    onAccent: AppColors.ink,
    accentSoft: AppColors.sun100,
    danger: AppColors.clay600,
    dangerSoft: AppColors.clay50,
    warning: AppColors.sun700,
    success: AppColors.brand600,
  );

  static const dark = OuvraPalette(
    background: Color(0xFF0E1310),
    paper: Color(0xFF121814),
    muted: Color(0xFF1B221D),
    mutedForeground: Color(0xFF9AA398),
    subtle: Color(0xFF7D867B),
    border: Color(0xFF29312B),
    ink: Color(0xFFE9EDE8),
    primary: AppColors.brand300,
    onPrimary: AppColors.brand950,
    primarySoft: Color(0xFF15281F),
    accent: AppColors.sun400,
    onAccent: AppColors.ink,
    accentSoft: Color(0xFF3A2E0A),
    danger: AppColors.clay400,
    dangerSoft: Color(0xFF2A130D),
    warning: AppColors.sun300,
    success: AppColors.brand300,
  );

  @override
  OuvraPalette copyWith() => this;

  @override
  OuvraPalette lerp(OuvraPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return OuvraPalette(
      background: l(background, other.background),
      paper: l(paper, other.paper),
      muted: l(muted, other.muted),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      subtle: l(subtle, other.subtle),
      border: l(border, other.border),
      ink: l(ink, other.ink),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primarySoft: l(primarySoft, other.primarySoft),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      warning: l(warning, other.warning),
      success: l(success, other.success),
    );
  }
}

extension OuvraPaletteContext on BuildContext {
  OuvraPalette get palette => Theme.of(this).extension<OuvraPalette>()!;
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Thèmes Ouvra. Surfaces à plat, séparées par des filets plutôt que par des
/// ombres ; le jaune taxi n'apparaît que sur l'action principale.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, OuvraPalette.light);
  static ThemeData get dark => _build(Brightness.dark, OuvraPalette.dark);

  static ThemeData _build(Brightness brightness, OuvraPalette p) {
    final text = AppTypography.textTheme(p.ink, p.mutedForeground);
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.primary,
      secondary: p.accent,
      onSecondary: p.onAccent,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.ink,
      error: p.danger,
      onError: Colors.white,
      surface: p.background,
      onSurface: p.ink,
      onSurfaceVariant: p.mutedForeground,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.paper,
      surfaceContainer: p.paper,
      surfaceContainerHigh: p.muted,
      surfaceContainerHighest: p.muted,
      outline: p.border,
      outlineVariant: p.border,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
    );

    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      extensions: [p],
      splashFactory: InkRipple.splashFactory,
      splashColor: p.ink.withValues(alpha: 0.06),
      highlightColor: p.ink.withValues(alpha: 0.04),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      iconTheme: IconThemeData(color: p.ink, size: 22),
      dividerTheme: DividerThemeData(color: p.border, thickness: 0.5, space: 0.5),
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.screen,
        iconColor: p.ink,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.muted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: text.bodyLarge?.copyWith(color: p.subtle),
        prefixIconColor: p.mutedForeground,
        suffixIconColor: p.mutedForeground,
        errorStyle: text.bodySmall?.copyWith(color: p.danger),
        border: field(Colors.transparent),
        enabledBorder: field(Colors.transparent),
        focusedBorder: field(p.primary, 1.5),
        errorBorder: field(p.danger),
        focusedErrorBorder: field(p.danger, 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.2),
        selectionHandleColor: p.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: text.labelLarge,
          minimumSize: const Size(44, 44),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.muted,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.primary : p.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.gray100 : AppColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(
            color: isDark ? AppColors.ink : Colors.white),
        actionTextColor: AppColors.sun400,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        modalBackgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.primary,
        headerForegroundColor: p.onPrimary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.background,
      ),
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: p.primary),
    );
  }
}

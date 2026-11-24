import 'package:flutter/material.dart';

import 'app_tokens.dart';

export 'app_tokens.dart';

abstract final class AppTheme {
  static const String fontFamily = 'Plus Jakarta Sans';
  static const Color canvas = AppColors.canvas;

  static const ColorScheme _scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand600,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brand50,
    onPrimaryContainer: AppColors.brand700,
    // Tombol tonal dan indikator navigasi memakai peran ini.
    secondary: AppColors.brand700,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.brand50,
    onSecondaryContainer: AppColors.brand700,
    tertiary: AppColors.sakitInk,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.sakitTint,
    onTertiaryContainer: AppColors.sakitInk,
    error: AppColors.alfaInk,
    onError: Colors.white,
    errorContainer: AppColors.alfaTint,
    onErrorContainer: AppColors.alfaInk,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.surfaceSubtle,
    surfaceContainer: AppColors.canvas,
    surfaceContainerHigh: AppColors.surfaceInset,
    surfaceContainerHighest: AppColors.surfaceInset,
    outline: AppColors.fieldLine,
    outlineVariant: AppColors.line,
    inverseSurface: AppColors.ink,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.brand200,
    scrim: AppColors.scrim,
    shadow: AppColors.scrim,
  );

  static final TextTheme _text = _buildTextTheme();

  static TextTheme _buildTextTheme() {
    TextStyle s(
      double size,
      FontWeight weight,
      double height, [
      double tracking = 0,
    ]) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking,
      color: AppColors.ink,
    );
    return TextTheme(
      displayLarge: s(42, FontWeight.w800, 1.06, -1.6),
      displaySmall: s(36, FontWeight.w800, 1.1, -1.2),
      headlineLarge: s(32, FontWeight.w800, 1.12, -1.4),
      headlineMedium: s(27, FontWeight.w800, 1.15, -0.9),
      headlineSmall: s(23, FontWeight.w800, 1.2, -0.5),
      titleLarge: s(20, FontWeight.w800, 1.25, -0.6),
      titleMedium: s(16.5, FontWeight.w700, 1.3, -0.2),
      titleSmall: s(14, FontWeight.w600, 1.4),
      bodyLarge: s(16, FontWeight.w400, 1.55),
      bodyMedium: s(14, FontWeight.w400, 1.5),
      bodySmall: s(12.5, FontWeight.w500, 1.4),
      labelLarge: s(15, FontWeight.w600, 1.2),
      labelMedium: s(12.5, FontWeight.w600, 1.3),
      labelSmall: s(12, FontWeight.w600, 1.3),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.control,
        borderSide: BorderSide(color: color, width: width),
      );

  static const _controlShape = RoundedRectangleBorder(
    borderRadius: AppRadius.control,
  );

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: _scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: _text,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: AppSpacing.page,
      titleTextStyle: _text.titleLarge?.copyWith(fontSize: 19),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Color(0x1A0C1B33),
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, AppSizes.control),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        textStyle: _text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        elevation: 0,
        shape: _controlShape,
        disabledBackgroundColor: AppColors.surfaceInset,
        disabledForegroundColor: AppColors.inkFaint,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, AppSizes.control),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        foregroundColor: AppColors.ink,
        textStyle: _text.labelLarge,
        side: const BorderSide(color: AppColors.fieldLine),
        shape: _controlShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        foregroundColor: AppColors.brand700,
        textStyle: _text.labelLarge?.copyWith(fontSize: 14),
        shape: _controlShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSizes.touch, AppSizes.touch),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brand600,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      hintStyle: _text.bodyLarge?.copyWith(color: AppColors.inkFaint),
      labelStyle: _text.bodyLarge?.copyWith(color: AppColors.inkMuted),
      helperStyle: _text.bodySmall?.copyWith(color: AppColors.inkMuted),
      helperMaxLines: 3,
      errorStyle: _text.bodySmall?.copyWith(color: AppColors.alfaInk),
      errorMaxLines: 3,
      prefixIconColor: AppColors.inkFaint,
      suffixIconColor: AppColors.inkFaint,
      border: _fieldBorder(AppColors.fieldLine),
      enabledBorder: _fieldBorder(AppColors.fieldLine),
      disabledBorder: _fieldBorder(AppColors.lineStrong),
      focusedBorder: _fieldBorder(AppColors.brand600, 2),
      errorBorder: _fieldBorder(AppColors.alfaInk),
      focusedErrorBorder: _fieldBorder(AppColors.alfaInk, 2),
    ),    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.brand600,
      selectionColor: AppColors.brand200,
      selectionHandleColor: AppColors.brand600,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.brand600,
      showCheckmark: false,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? AppColors.brand600
              : AppColors.lineStrong,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      labelStyle: _text.titleSmall?.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.inkMuted,
        ),
      ),
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.touch)),
        textStyle: WidgetStatePropertyAll(_text.titleSmall),
        shape: const WidgetStatePropertyAll(_controlShape),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.lineStrong),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand50
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.inkMuted,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      indicatorColor: AppColors.brand50,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => _text.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.inkFaint,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? AppColors.brand700
              : AppColors.inkFaint,
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minTileHeight: 56,
      iconColor: AppColors.inkMuted,
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: _text.titleLarge,
      contentTextStyle: _text.bodyMedium?.copyWith(color: AppColors.inkMuted),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: AppColors.lineStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      textStyle: _text.bodyMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      actionTextColor: AppColors.brand200,
      contentTextStyle: _text.bodyMedium?.copyWith(color: Colors.white),
      shape: _controlShape,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand600,
      linearTrackColor: AppColors.surfaceInset,
    ),
  );
}

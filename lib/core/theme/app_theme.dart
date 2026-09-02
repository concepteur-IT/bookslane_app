import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_durations.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the tokens into the two [ThemeData]s the app runs on.
///
/// Role mapping (deliberate — see the sign-in design):
/// * `primary`   → [AppColors.ctaBackground] (red). Drives every call to
///   action, link and selection accent.
/// * `secondary` → [AppColors.brandPrimary] (purple). Brand surfaces, headers,
///   in-sentence links.
/// * `error`     → [AppColors.errorText] — the same red, so validation
///   introduces no new hue.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  /// Status bar styling for screens topped by the purple brand header.
  static const SystemUiOverlayStyle brandOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    // Surfaces and text are the only roles that differ between the themes.
    final Color screenBackground = isLight
        ? AppColors.screenBackground
        : AppColorsDark.screenBackground;
    final Color surfaceBackground = isLight
        ? AppColors.surfaceBackground
        : AppColorsDark.surfaceBackground;
    final Color inputBackground = isLight
        ? AppColors.inputBackground
        : AppColorsDark.inputBackground;
    final Color inputBorder = isLight
        ? AppColors.inputBorder
        : AppColorsDark.inputBorder;
    final Color borderColor = isLight
        ? AppColors.borderColor
        : AppColorsDark.borderColor;
    final Color dividerColor = isLight
        ? AppColors.dividerColor
        : AppColorsDark.dividerColor;
    final Color headingText = isLight
        ? AppColors.headingText
        : AppColorsDark.headingText;
    final Color mutedText = isLight
        ? AppColors.mutedText
        : AppColorsDark.mutedText;
    final Color iconPrimary = isLight
        ? AppColors.iconPrimary
        : AppColorsDark.iconPrimary;
    final Color brandOnSurface = isLight
        ? AppColors.brandPrimary
        : AppColorsDark.brandOnDark;
    final Color snackBarBackground = isLight
        ? AppColors.snackBarBackground
        : AppColorsDark.snackBarBackground;

    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      primary: AppColors.ctaBackground,
      onPrimary: AppColors.ctaText,
      primaryContainer: isLight
          ? AppColors.errorBackground
          : AppColors.ctaBackgroundPressed,
      onPrimaryContainer: isLight
          ? AppColors.ctaBackgroundPressed
          : AppColors.ctaText,
      secondary: brandOnSurface,
      onSecondary: isLight ? AppColors.inverseText : AppColors.brandPrimaryDark,
      secondaryContainer: isLight
          ? AppColors.brandSoftBackground
          : AppColors.brandPrimaryDark,
      onSecondaryContainer: isLight
          ? AppColors.brandPrimaryDark
          : AppColors.inverseText,
      tertiary: AppColors.logoGlyph,
      onTertiary: AppColors.inverseText,
      error: AppColors.errorText,
      onError: AppColors.inverseText,
      surface: surfaceBackground,
      onSurface: headingText,
      outline: borderColor,
      shadow: AppColors.raisedShadow,
      scrim: AppColors.modalScrim,
    );

    final TextTheme textTheme = AppTypography.textTheme(headingText, mutedText);

    final OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(
        color: inputBorder,
        width: AppSizes.borderWidth,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      scaffoldBackgroundColor: screenBackground,
      splashFactory: InkRipple.splashFactory,

      // Native slide transition on Apple platforms, Material defaults elsewhere.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surfaceBackground,
        foregroundColor: headingText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: headingText, size: AppSizes.iconLg),
      ),

      iconTheme: IconThemeData(color: iconPrimary, size: AppSizes.iconMd),

      // ---------------------------------------------------------------------
      // Inputs — filled, 16px radius, icon-led, no visible border at rest.
      // ---------------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md + AppSpacing.xxs,
          horizontal: AppSpacing.xxs,
        ),
        prefixIconColor: iconPrimary,
        suffixIconColor: mutedText,
        hintStyle: AppTypography.hint,
        labelStyle: AppTypography.fieldLabel,
        floatingLabelStyle: AppTypography.fieldLabel.copyWith(
          color: AppColors.inputBorderFocused,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.errorText,
        ),
        border: baseBorder,
        enabledBorder: baseBorder,
        disabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: AppSizes.borderWidthFocused,
          ),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.inputBorderError),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.inputBorderError,
            width: AppSizes.borderWidthFocused,
          ),
        ),
      ),

      // ---------------------------------------------------------------------
      // Buttons
      // Solid red fill. For the gradient call to action use
      // `AppDecorations.ctaButton` on a Container + InkWell instead.
      // ---------------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaBackground,
          foregroundColor: AppColors.ctaText,
          disabledBackgroundColor: AppColors.ctaBackgroundDisabled,
          disabledForegroundColor: AppColors.ctaText,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryButtonText,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: BorderSide(color: borderColor),
          textStyle: AppTypography.button.copyWith(
            color: AppColors.secondaryButtonText,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.linkText,
          textStyle: AppTypography.link,
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),

      // ---------------------------------------------------------------------
      // Surfaces & feedback
      // ---------------------------------------------------------------------
      cardTheme: CardThemeData(
        color: surfaceBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: borderColor),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.dragHandle,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarBackground,
        contentTextStyle: AppTypography.bodyLarge.copyWith(
          color: AppColors.snackBarText,
        ),
        actionTextColor: AppColors.snackBarActionText,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: AppSizes.borderWidth,
        space: AppSpacing.lg,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.ctaBackground,
        linearTrackColor: inputBackground,
        circularTrackColor: inputBackground,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.controlSelected
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.inverseText),
        side: BorderSide(color: inputBorder, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xsAll),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.inverseText),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.controlSelected
              : inputBorder,
        ),
      ),

      // Material 3 bottom bar — the pill indicator behind the selected icon.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isLight
            ? AppColors.navIndicatorBackground
            : AppColors.brandPrimaryDark,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pillAll,
        ),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.iconLg,
            color: states.contains(WidgetState.selected)
                ? AppColors.navItemSelected
                : AppColors.navItemUnselected,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTypography.caption.copyWith(
                  color: AppColors.navItemSelected,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.caption.copyWith(
                  color: AppColors.navItemUnselected,
                ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceBackground,
        selectedItemColor: AppColors.navItemSelected,
        unselectedItemColor: mutedText,
        selectedLabelStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: AppDurations.medium,
        decoration: const BoxDecoration(
          color: AppColors.tooltipBackground,
          borderRadius: AppRadius.xsAll,
        ),
        textStyle: AppTypography.caption.copyWith(
          color: AppColors.tooltipText,
        ),
      ),
    );
  }
}

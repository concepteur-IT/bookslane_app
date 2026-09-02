# Bookslane Design System

Single source of truth for colour, type, spacing, motion and component styling.
All tokens are derived from the sign-in reference design.

```dart
import 'package:bookslane_app/core/theme/theme.dart';
```

## Rules

1. **No raw values in feature code.** No `Color(0xFF...)`, no `fontSize: 17`, no
   `EdgeInsets.all(13)`. If a value is missing, add a token here first.
2. **Name colours by role, never by hue.** Use `AppColors.ctaBackground`, not
   `AppPalette.red500` and never `Color(0xFFD01E1E)`. If no role fits, add one.
3. **Prefer the theme over the tokens.** `Theme.of(context).colorScheme.primary`
   and `Theme.of(context).textTheme.*` adapt to light/dark; the `AppColors`
   constants do not. Reach for constants only for brand elements that never
   change (the purple header, the red gradient button, decorative shadows).
4. **Component styling belongs in `app_theme.dart`**, not in the widget. If two
   screens style the same widget differently, one of them is wrong.

## Two colour layers

`app_palette.dart` holds the raw hues (`AppPalette.red500`). Nothing outside the
theme folder should touch it. `app_colors.dart` names those hues by **where they
go** — that is the layer you write screens with:

```dart
Container(color: AppColors.ctaBackground)      // yes — says what it is for
Container(color: AppPalette.red500)            // no  — says only what it is
```

Rebranding then means editing `AppPalette` alone.

## Files

| File | Contains |
| --- | --- |
| `app_palette.dart` | Raw hues — `purple500`, `red500`, `neutral300`, ... (theme-internal) |
| `app_colors.dart` | Role-named tokens (`ctaBackground`, `inputBorder`, `headingText`) + `AppColorsDark` |
| `app_typography.dart` | Type scale + the Material `TextTheme` mapping |
| `app_spacing.dart` | `AppSpacing` (4pt grid), `AppRadius`, `AppSizes` |
| `app_gradients.dart` | `brandHeader`, `ctaButton`, `skeletonShimmer` |
| `app_shadows.dart` | `card`, `raised`, `ctaButton` glow, `bottomBar` |
| `app_decorations.dart` | Ready-made `BoxDecoration`s (`ctaButton`, `sheet`, `brandHeader`, `logoTile`, `card`) |
| `app_durations.dart` | `AppDurations` + `AppCurves` motion tokens |
| `app_theme.dart` | `AppTheme.light` / `AppTheme.dark` and every component theme |
| `theme.dart` | Barrel export — import this one |

## Colour tokens by role

**Call to action** (the red button)

| Token | Value |
| --- | --- |
| `ctaBackground` | `#D01E1E` |
| `ctaBackgroundPressed` | `#A81717` |
| `ctaBackgroundDisabled` | `#B4BCC7` |
| `ctaGradientStart` → `ctaGradientEnd` | `#E23A30` → `#D01E1E` |
| `ctaText` / `ctaIcon` | white |
| `ctaShadow` | red @ 25% |

**Brand header** (the purple block)

`brandPrimary #463289` · `brandHeaderGradientStart/End #463289 → #2E2062` ·
`brandHeaderText` white · `brandHeaderSubtitleText` white @ 80% ·
`logoTileBackground`, `logoRingBorder`, `logoGlyph`, `logoLetter`

**Inputs**

`inputBackground #F6F8FA` · `inputBorder #EBEFF3` ·
`inputBorderFocused #463289` · `inputBorderError #D01E1E` · `inputText` ·
`inputHintText` · `inputPrefixIcon` · `inputSuffixIcon` · `inputLabelText` ·
`inputCursor`

**Text**

`headingText #1B1B2F` → `secondaryText #4E5D6B` → `mutedText #9AA3B0` →
`disabledText #B4BCC7` · `inverseText` white

**Links**: `linkText` (red, standalone) · `linkTextBrand` (purple, in a sentence)

**Surfaces**: `screenBackground` · `surfaceBackground` · `sheetBackground` ·
`dialogBackground` · `modalScrim`

**Lines & controls**: `borderColor` · `dividerColor` · `iconPrimary` ·
`iconMuted` · `focusRing` · `controlSelected` · `navItemSelected` ·
`navItemUnselected`

**Status**: `successText`/`successBackground`, `warningText`/`warningBackground`,
`infoText`/`infoBackground`, `errorText`/`errorBackground` (error reuses the CTA
red so the UI never gains a second red).

**Feedback**: `snackBarBackground`/`snackBarText`/`snackBarActionText` ·
`tooltipBackground`/`tooltipText` · `skeletonBase`/`skeletonHighlight`

## Material role mapping

`colorScheme.primary` = `ctaBackground` (red) so stock buttons and focus states
are correct out of the box. `colorScheme.secondary` = `brandPrimary` (purple).
Prefer `Theme.of(context)` where a role exists — it adapts to dark mode; reach
for `AppColors` directly for brand elements that never change.

## Recipes

**Call to action** — `ElevatedButton` gives the flat red button. For the
gradient version from the mockup:

```dart
Container(
  height: AppSizes.buttonHeight,
  decoration: AppDecorations.ctaButton,
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: AppRadius.lgAll,
      onTap: onPressed,
      child: Center(child: Text('SIGN IN', style: AppTypography.button)),
    ),
  ),
)
```

**Auth screen shell** — purple header + white sheet:

```dart
Container(
  decoration: AppDecorations.brandHeader,
  child: Column(
    children: [
      const _Branding(),
      Container(
        decoration: AppDecorations.sheet,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page, AppSpacing.xl, AppSpacing.page, AppSpacing.lg,
        ),
        child: form,
      ),
    ],
  ),
)
```

**Field with label**

```dart
Text('EMAIL', style: AppTypography.fieldLabel),
const SizedBox(height: AppSpacing.labelGap),
TextFormField(decoration: const InputDecoration(hintText: 'you@example.com')),
```

The `InputDecorationTheme` already supplies the fill, 16px radius, padding,
hint style and focus/error borders — pass only content.

## Fonts

The reference design uses Poppins. `AppTypography.fontFamily` is `null` until
the family ships with the app, so text currently renders in the platform font.
To enable it: add the `.ttf` files under `assets/fonts/`, declare the family in
`pubspec.yaml`, then set `fontFamily` to `'Poppins'` — nothing else changes.

## Dark theme

`AppTheme.dark` is wired up and exercised, but the mockup only covers light
mode, so its surface ramp is derived rather than designed. `main.dart` pins
`themeMode: ThemeMode.light`; switch to `ThemeMode.system` once dark mode has a
design review.

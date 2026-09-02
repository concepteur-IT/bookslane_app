import 'package:flutter/material.dart';

/// Raw colour values — the primitive layer. Sampled from the sign-in design.
///
/// **Do not use these in widgets.** They say what a colour *is*, not what it is
/// *for*. Build screens from the role-named tokens in `app_colors.dart`
/// (`AppColors.ctaBackground`, `AppColors.inputBorder`, ...) so a palette
/// change never means hunting through feature code.
abstract final class AppPalette {
  // Purple — brand identity.
  static const Color purple50 = Color(0xFFEDE9F7);
  static const Color purple500 = Color(0xFF463289);
  static const Color purple700 = Color(0xFF2E2062);
  static const Color purple900 = Color(0xFF241A4E);

  // Red — the action colour.
  static const Color red50 = Color(0xFFFDECEC);
  static const Color red400 = Color(0xFFE23A30);
  static const Color red500 = Color(0xFFD01E1E);
  static const Color red700 = Color(0xFFA81717);

  // Navy — the logo glyph.
  static const Color navy700 = Color(0xFF14245A);

  // Neutrals, light to dark.
  static const Color white = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF6F8FA);
  static const Color neutral100 = Color(0xFFF2F4F7);
  static const Color neutral200 = Color(0xFFEEF1F5);
  static const Color neutral300 = Color(0xFFEBEFF3);
  static const Color neutral400 = Color(0xFFB4BCC7);
  static const Color neutral500 = Color(0xFF9AA3B0);
  static const Color neutral700 = Color(0xFF4E5D6B);
  static const Color neutral900 = Color(0xFF1B1B2F);

  // Neutrals for dark mode.
  static const Color darkNeutral50 = Color(0xFFF4F4F8);
  static const Color darkNeutral600 = Color(0xFF322F45);
  static const Color darkNeutral700 = Color(0xFF242336);
  static const Color darkNeutral800 = Color(0xFF1B1A28);
  static const Color darkNeutral900 = Color(0xFF12111C);

  // Status hues.
  static const Color green50 = Color(0xFFE6F6EF);
  static const Color green500 = Color(0xFF1E9E6A);
  static const Color amber50 = Color(0xFFFDF3DF);
  static const Color amber500 = Color(0xFFE5A100);
  static const Color blue50 = Color(0xFFEAF1FE);
  static const Color blue500 = Color(0xFF2F6FED);

  // Translucent overlays.
  static const Color white80 = Color(0xCCFFFFFF);
  static const Color black20 = Color(0x33000000);
  static const Color black60 = Color(0x99000000);
  static const Color black08 = Color(0x14101828);
  static const Color black06 = Color(0x0F101828);
  static const Color red25 = Color(0x40D01E1E);
}

import 'package:flutter/widgets.dart';

/// Spacing scale — a 4pt grid. Never hard-code an `EdgeInsets` value that is
/// not one of these steps.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 56;

  /// Horizontal gutter for full-page content.
  static const double page = 24;

  /// Vertical rhythm between a field label and its input.
  static const double labelGap = 10;

  /// Vertical rhythm between two form fields.
  static const double fieldGap = 22;

  /// Standard page padding (horizontal gutter only).
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: page);
}

/// Corner radii. `md` is the input radius, `lg` the button radius and `sheet`
/// the rounded card that overlaps the auth header.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 26;
  static const double sheet = 36;
  static const double pill = 999;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-rounded sheet used for the white card on the auth screens.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Fixed component sizes taken from the reference design.
abstract final class AppSizes {
  static const double buttonHeight = 60;
  static const double buttonHeightSm = 44;
  static const double inputHeight = 60;

  static const double iconSm = 18;
  static const double iconMd = 21;
  static const double iconLg = 24;

  static const double borderWidth = 1;
  static const double borderWidthFocused = 1.4;

  /// Rounded white logo tile and the red circle inside it.
  static const double logoTile = 92;
  static const double logoMark = 56;

  /// Square icon tiles on cards — stat tiles, list leading icons.
  static const double tileMd = 48;
  static const double tileLg = 56;

  /// Notification count bubble.
  static const double badge = 20;

  /// Minimum tap target (Material + iOS accessibility guidance).
  static const double minTapTarget = 48;
}

/// Shared widgets — the building blocks every feature composes screens from.
///
/// Import this single file to reach them all:
///
/// ```dart
/// import 'package:bookslane_app/core/widgets/widgets.dart';
/// ```
///
/// What belongs here: a widget with no feature knowledge that two or more
/// screens could use. Anything that knows about auth, books or orders belongs
/// in that feature's own `presentation/widgets/` folder instead.
library;

export 'app_search_field.dart';
export 'app_text_field.dart';
export 'app_toast.dart';
export 'choice_chip_button.dart';
export 'pagination_bar.dart';
export 'cta_button.dart';
export 'field_label.dart';
export 'inner_page_app_bar.dart';
export 'status_pill.dart';

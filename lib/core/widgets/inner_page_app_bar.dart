import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// App bar for an inner page — one level below a tab's root.
///
/// Replaces the branded [DashboardAppBar] (logo + "Bookslane" + section) with
/// what actually matters here: where you are, how to get back, and the
/// screen's own actions. The optional [searchField] rides in the bar too, so
/// the page body starts higher up.
///
/// Roughly 90pt of vertical space back compared with a branded bar plus an
/// in-body title row and search box.
class InnerPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InnerPageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.searchField,
  });

  final String title;

  /// Small line under the title — a count, a filter summary.
  final String? subtitle;

  /// Omit to hide the back button (a tab root).
  final VoidCallback? onBack;

  final List<Widget> actions;

  /// Usually an [AppSearchField]; occupies a second row inside the bar.
  final Widget? searchField;

  static const double _barHeight = 60;

  /// Deliberately a little more than the field needs. A bar that is short by a
  /// pixel overflows; one that is long by a few just breathes, and the exact
  /// height of a text field varies with the platform's text scaling.
  static const double _searchHeight = 80;

  @override
  Size get preferredSize => Size.fromHeight(
    _barHeight + (searchField == null ? 0 : _searchHeight),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _barHeight,
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.iconPrimary,
                    )
                  else
                    const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineMedium,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),

                  ...actions,
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),

            if (searchField != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: searchField,
              ),
          ],
        ),
      ),
    );
  }
}

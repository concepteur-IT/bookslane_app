import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/app_search_field.dart';

/// The row above a list: a search box, then the filter and sort buttons —
/// the Shop and My Store lists share it. Put [key] on it and pass that to
/// `showAnchoredPanel`, so the overlays drop down from under this row.
class ListToolbar extends StatelessWidget {
  const ListToolbar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.onSortPressed,
    this.searchHint = 'Search books',
    this.filterCount = 0,
    this.isSorted = false,
    this.trailing = const [],
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;
  final String searchHint;

  /// Filters in use; badges the filter button when above zero.
  final int filterCount;

  /// Whether the sort differs from the list's default; tints the button.
  final bool isSorted;

  /// Extra buttons after sort — each gets the same gap before it.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            dense: true,
            hintText: searchHint,
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        ToolbarIconButton(
          icon: Icons.filter_alt_outlined,
          tooltip: 'Filter',
          isActive: filterCount > 0,
          badge: filterCount > 0 ? '$filterCount' : null,
          onPressed: onFilterPressed,
        ),
        const SizedBox(width: AppSpacing.xs),
        ToolbarIconButton(
          icon: Icons.swap_vert_rounded,
          tooltip: 'Sort',
          isActive: isSorted,
          onPressed: onSortPressed,
        ),
        for (final widget in trailing) ...[
          const SizedBox(width: AppSpacing.xs),
          widget,
        ],
      ],
    );
  }
}

/// A square outlined icon button the height of the dense search field.
/// Tinted purple while its setting is in use; [badge] counts active filters.
class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;
  final String? badge;

  static const double _size = AppSizes.minTapTarget;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.mdAll,
      side: BorderSide(
        color: isActive ? AppColors.brandPrimary : AppColors.inputBorder,
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: isActive
                ? AppColors.brandSoftBackground
                : AppColors.surfaceBackground,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: onPressed,
              child: SizedBox(
                width: _size,
                height: _size,
                child: Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: isActive
                      ? AppColors.brandPrimary
                      : AppColors.iconPrimary,
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -AppSpacing.xxs,
              right: -AppSpacing.xxs,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.badge,
                    minHeight: AppSizes.badge,
                  ),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ctaBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inverseText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

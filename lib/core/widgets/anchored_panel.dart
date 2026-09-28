import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// Drops a panel down from just under [anchor] — a list screen's toolbar —
/// the same way the notifications panel hangs off the app bar: no dimmed
/// page, tap outside to close. Resolves to whatever the panel pops with, or
/// null when dismissed.
///
/// The panel is as wide as [anchor], or [maxWidth] if that's narrower, and
/// right-aligned under it. Used by the filter and sort overlays on the Shop
/// and My Store lists.
Future<T?> showAnchoredPanel<T>({
  required BuildContext context,
  required GlobalKey anchor,
  required WidgetBuilder builder,
  double maxWidth = double.infinity,
}) {
  final box = anchor.currentContext!.findRenderObject()! as RenderBox;
  final anchorRect = box.localToGlobal(Offset.zero) & box.size;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.fast,
    // Measured against the space the route actually lays out in, not
    // MediaQuery's screen size — the two can differ (split screen, tests
    // with a custom surface), and the panel must line up with the anchor.
    pageBuilder: (context, _, _) => LayoutBuilder(
      builder: (context, constraints) {
        final top = anchorRect.bottom + AppSpacing.xs;

        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(
              top: top,
              left: anchorRect.left,
              right: math.max(0, constraints.maxWidth - anchorRect.right),
            ),
            child: ConstrainedBox(
              // An exact width, not just a cap: panel content (chips, rows)
              // doesn't ask for width, so a loose constraint would shrink
              // the panel to nothing.
              constraints:
                  BoxConstraints.tightFor(
                    width: math.min(maxWidth, anchorRect.width),
                  ).copyWith(
                    // Stop above the bottom bar with a little page showing.
                    maxHeight:
                        constraints.maxHeight - top - AppSpacing.xxxl * 2,
                  ),
              // Shadow outside, clip inside — a clipping Material would cut
              // its own shadow off.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgAll,
                  boxShadow: AppShadows.raised,
                ),
                child: Material(
                  color: AppColors.surfaceBackground,
                  borderRadius: AppRadius.lgAll,
                  clipBehavior: Clip.antiAlias,
                  child: builder(context),
                ),
              ),
            ),
          ),
        );
      },
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.standard,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

/// A "Sort by" list for [showAnchoredPanel]. One tap picks an order and
/// closes; the current one is ticked. Clear pops [initial], and is disabled
/// while that's already selected.
class SortPanel<T> extends StatelessWidget {
  const SortPanel({
    super.key,
    required this.options,
    required this.selected,
    required this.initial,
    required this.labelOf,
  });

  final List<T> options;
  final T selected;
  final T initial;
  final String Function(T) labelOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PanelHeading('Sort by'),
                for (final option in options)
                  _SortOption(
                    label: labelOf(option),
                    isSelected: option == selected,
                    onTap: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: OutlinedButton(
            onPressed: selected == initial
                ? null
                : () => Navigator.of(context).pop(initial),
            child: const Text('CLEAR'),
          ),
        ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: isSelected
                      ? AppColors.brandPrimary
                      : AppColors.bodyText,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: AppSizes.iconMd,
                color: AppColors.brandPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

/// The frame of a filter panel for [showAnchoredPanel]: [sections] scroll,
/// with a pinned RESET / apply row under them. The caller owns the draft —
/// [onReset] clears it (null disables RESET), [onApply] pops it.
class FilterPanelFrame extends StatelessWidget {
  const FilterPanelFrame({
    super.key,
    required this.sections,
    required this.onReset,
    required this.onApply,
    this.applyLabel = 'APPLY',
  });

  final List<Widget> sections;
  final VoidCallback? onReset;
  final VoidCallback onApply;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sections,
            ),
          ),
        ),

        const Divider(height: 1),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 2:3 rather than 1:2, and labels that shrink rather than
              // wrap: at 360pt a third of the row broke RESET over two lines.
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const _OneLineLabel('RESET'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: onApply,
                  child: _OneLineLabel(applyLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A button label kept on one line, scaled down if the button is too narrow.
class _OneLineLabel extends StatelessWidget {
  const _OneLineLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, softWrap: false),
    );
  }
}

/// An uppercase section label inside a panel, with an optional value on the
/// right (the price range, say).
class PanelHeading extends StatelessWidget {
  const PanelHeading(this.label, {super.key, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label.toUpperCase(), style: AppTypography.fieldLabel),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTypography.caption.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// Chips wrapped onto as many lines as they need, at the panel's gutter.
class PanelChipWrap extends StatelessWidget {
  const PanelChipWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: children,
      ),
    );
  }
}

/// A label with a switch on the right.
class PanelSwitchRow extends StatelessWidget {
  const PanelSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

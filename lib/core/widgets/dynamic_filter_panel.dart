import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/anchored_panel.dart';
import 'package:bookslane_app/core/widgets/choice_chip_button.dart';

/// Asks the screen's `/filters` endpoint what the panel can offer if the user
/// keeps [draft]. Throws [ApiFailure] on failure.
typedef FacetsLoader = Future<FilterFacets> Function(CatalogFilters draft);

/// A filter overlay whose options come from the server rather than from lists
/// compiled into the app. Used by My Store, My Publishings and the Shop —
/// [spec] says which sections each shows.
///
/// It edits a draft; nothing changes on the page until Apply, which pops the
/// new [CatalogFilters] (null if dismissed). But the *options* stay live: every
/// change to the draft re-asks the server (debounced) what that selection
/// leaves, so the counts beside each chip, the price range, and the "SHOW N"
/// button always describe what Apply would give. Other options stay listed when
/// you pick one — see [FilterFacets].
class DynamicFilterPanel extends StatefulWidget {
  const DynamicFilterPanel({
    super.key,
    required this.spec,
    required this.initial,
    required this.loadFacets,
    this.debounce = const Duration(milliseconds: 250),
  });

  final FilterSpec spec;

  /// What is applied on the page right now — the draft's starting point.
  final CatalogFilters initial;

  final FacetsLoader loadFacets;

  /// How long to wait after the last change before asking the server.
  final Duration debounce;

  @override
  State<DynamicFilterPanel> createState() => _DynamicFilterPanelState();
}

/// How many chips a category or language section shows before "Show all".
const int _collapsedChipCount = 12;

class _DynamicFilterPanelState extends State<DynamicFilterPanel> {
  late CatalogFilters _draft = widget.initial;

  FilterFacets? _facets;
  bool _loading = true;
  bool _failed = false;

  /// Guards against an older response landing after a newer one.
  int _request = 0;
  Timer? _timer;

  bool _showAllCategories = false;
  bool _showAllLanguages = false;

  FilterSpec get _spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final facets = await widget.loadFacets(_draft);
      if (!mounted || request != _request) return;
      setState(() {
        _facets = facets;
        _loading = false;
      });
    } on ApiFailure {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Applies [next] to the draft, then — after a pause, so a run of taps is
  /// one request — refreshes the options.
  void _change(CatalogFilters next) {
    setState(() => _draft = next);
    _timer?.cancel();
    _timer = Timer(widget.debounce, _load);
  }

  void _reset() {
    _timer?.cancel();
    setState(() => _draft = _spec.initial);
    _load();
  }

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  void _toggleStatus(bool isActive) => _change(
    _draft.isActive == isActive
        ? _draft.copyWith(clearIsActive: true)
        : _draft.copyWith(isActive: isActive),
  );

  void _toggleCategory(FacetOption option) {
    final selected = _draft.categories;
    final Set<FacetOption> next;
    if (selected.contains(option)) {
      next = {...selected}..remove(option);
    } else if (_spec.multiCategory) {
      next = {...selected, option};
    } else {
      next = {option}; // single choice: picking another replaces
    }
    _change(_draft.copyWith(categories: next));
  }

  void _toggleLanguage(FacetOption option) {
    final selected = _draft.languages;
    _change(
      _draft.copyWith(
        languages: selected.contains(option)
            ? ({...selected}..remove(option))
            : {...selected, option},
      ),
    );
  }

  void _setPrice(RangeValues values, PriceRange bounds) {
    final isFull = values.start <= bounds.min && values.end >= bounds.max;
    setState(() {
      _draft = isFull
          ? _draft.copyWith(clearPriceRange: true)
          : _draft.copyWith(
              priceRange: (
                min: values.start.roundToDouble(),
                max: values.end.roundToDouble(),
              ),
            );
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  /// The facet's options with whatever is selected but no longer returned
  /// (zero results under the other filters) kept in, so it can be un-picked.
  /// Selected first, then as the server ordered them.
  List<FacetOption> _optionsFor(
    List<FacetOption> fetched,
    Set<FacetOption> selected,
  ) {
    final byId = {for (final o in fetched) o.id: o};
    final picked = [for (final s in selected) byId[s.id] ?? s];
    return [
      ...picked,
      for (final o in fetched)
        if (!selected.contains(o)) o,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final facets = _facets;
    final total = facets?.total;
    final isSettled = facets != null && !_loading && !_failed;
    final noun = _spec.noun.toUpperCase();

    return FilterPanelFrame(
      onReset: _draft.isInitial(_spec.initial) ? null : _reset,
      onApply: () => Navigator.of(context).pop(_draft),
      applyLabel: isSettled && total != null
          ? 'SHOW $total ${total == 1 ? noun : '${noun}S'}'
          : 'APPLY',
      sections: [
        // Options stay on screen, dimmed, while a refresh is in flight —
        // swapping them for a spinner on every tap would make the panel jump.
        AnimatedOpacity(
          opacity: _loading && facets != null ? 0.5 : 1,
          duration: AppDurations.fast,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_spec.price) ..._priceSection(facets),
              if (_spec.status) ..._statusSection(facets),
              ..._availabilitySection(facets),
              ..._categorySection(facets),
              if (_spec.languages) ..._languageSection(facets),
              if (_failed) _FailureNote(onRetry: _load),
              if (_loading && facets == null) const _InitialSpinner(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _priceSection(FilterFacets? facets) {
    final bounds = facets?.price;
    // A slider needs room to slide; one price (or none) is nothing to filter.
    final usable = bounds != null && bounds.max > bounds.min;

    final range = _draft.priceRange;
    final values = usable
        ? RangeValues(
            (range?.min ?? bounds.min).clamp(bounds.min, bounds.max),
            (range?.max ?? bounds.max).clamp(bounds.min, bounds.max),
          )
        : null;

    return [
      PanelHeading(
        'Price',
        trailing: values == null
            ? null
            : '₹${values.start.round()} – ₹${values.end.round()}'
                  '${_draft.priceRange == null ? '+' : ''}',
      ),
      if (usable && values != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: RangeSlider(
            values: values,
            min: bounds.min,
            max: bounds.max,
            activeColor: AppColors.brandPrimary,
            inactiveColor: AppColors.brandSoftBackground,
            onChanged: (v) => _setPrice(v, bounds),
            // One request when the thumb is let go, not one per pixel.
            onChangeEnd: (_) => _change(_draft),
          ),
        )
      else if (facets != null && !_loading)
        const _Note('No price range to choose from.'),
    ];
  }

  List<Widget> _statusSection(FilterFacets? facets) {
    String label(String name, int? count) =>
        count == null ? name : '$name · $count';

    return [
      const PanelHeading('Status'),
      PanelChipWrap(
        children: [
          ChoiceChipButton(
            dense: true,
            label: label('Active', facets?.active),
            isSelected: _draft.isActive == true,
            onPressed: () => _toggleStatus(true),
          ),
          ChoiceChipButton(
            dense: true,
            label: label('Inactive', facets?.inactive),
            isSelected: _draft.isActive == false,
            onPressed: () => _toggleStatus(false),
          ),
        ],
      ),
    ];
  }

  List<Widget> _availabilitySection(FilterFacets? facets) => [
    const PanelHeading('Availability'),
    PanelSwitchRow(
      label: facets == null
          ? 'In stock only'
          : 'In stock only · ${facets.inStock}',
      value: _draft.inStockOnly,
      onChanged: (value) => _change(_draft.copyWith(inStockOnly: value)),
    ),
  ];

  List<Widget> _categorySection(FilterFacets? facets) => _chipSection(
    heading: 'Category',
    emptyNote: 'No categories for this selection.',
    facets: facets,
    options: facets == null
        ? const []
        : _optionsFor(facets.categories, _draft.categories),
    selected: _draft.categories,
    onToggle: _toggleCategory,
    showAll: _showAllCategories,
    onShowAll: () => setState(() => _showAllCategories = true),
  );

  List<Widget> _languageSection(FilterFacets? facets) => _chipSection(
    heading: 'Language',
    emptyNote: 'No languages for this selection.',
    facets: facets,
    options: facets == null
        ? const []
        : _optionsFor(facets.languages, _draft.languages),
    selected: _draft.languages,
    onToggle: _toggleLanguage,
    showAll: _showAllLanguages,
    onShowAll: () => setState(() => _showAllLanguages = true),
  );

  List<Widget> _chipSection({
    required String heading,
    required String emptyNote,
    required FilterFacets? facets,
    required List<FacetOption> options,
    required Set<FacetOption> selected,
    required ValueChanged<FacetOption> onToggle,
    required bool showAll,
    required VoidCallback onShowAll,
  }) {
    final visible = showAll
        ? options
        : options.take(_collapsedChipCount).toList();
    final hidden = options.length - visible.length;

    return [
      PanelHeading(heading),
      if (facets != null && options.isEmpty)
        _Note(emptyNote)
      else
        PanelChipWrap(
          children: [
            for (final option in visible)
              ChoiceChipButton(
                dense: true,
                label: option.count > 0
                    ? '${option.label} · ${option.count}'
                    : option.label,
                isSelected: selected.contains(option),
                onPressed: () => onToggle(option),
              ),
            if (hidden > 0)
              TextButton(
                onPressed: onShowAll,
                child: Text('Show all ${options.length}'),
              ),
          ],
        ),
    ];
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(text, style: AppTypography.bodySmall),
    );
  }
}

class _InitialSpinner extends StatelessWidget {
  const _InitialSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: AppSizes.iconLg,
          height: AppSizes.iconLg,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _FailureNote extends StatelessWidget {
  const _FailureNote({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Filter options couldn't be loaded.",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorText,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

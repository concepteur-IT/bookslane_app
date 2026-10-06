import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';

const poem = FacetOption(id: '1001', label: 'Poem', count: 338);
const thriller = FacetOption(id: '1004', label: 'Thriller', count: 70);
const bengali = FacetOption(id: 'Bengali', label: 'Bengali', count: 593);
const english = FacetOption(id: 'English', label: 'English', count: 42);

FilterFacets facets({
  int total = 100,
  List<FacetOption> categories = const [poem, thriller],
  List<FacetOption> languages = const [bengali, english],
  PriceRange? price = (min: 36, max: 1485),
  int inStock = 480,
  int? active,
  int? inactive,
}) => FilterFacets(
  total: total,
  categories: categories,
  languages: languages,
  price: price,
  inStock: inStock,
  active: active,
  inactive: inactive,
);

/// The Shop's panel: price, stock, category (several) and language.
const shopSpec = FilterSpec(
  initial: CatalogFilters(inStockOnly: true),
  price: true,
  languages: true,
  multiCategory: true,
);

/// The owner screens' panel: status, stock and one category.
const ownerSpec = FilterSpec(status: true);

void main() {
  late CatalogFilters? result;
  late bool closed;

  /// Opens the panel in a dialog, with a short debounce so tests don't wait.
  Future<void> open(
    WidgetTester tester, {
    required FacetsLoader loader,
    FilterSpec spec = shopSpec,
    CatalogFilters? initial,
  }) async {
    result = null;
    closed = false;
    await tester.binding.setSurfaceSize(const Size(420, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<CatalogFilters>(
                  context: context,
                  builder: (_) => Dialog(
                    child: SizedBox(
                      width: 380,
                      child: DynamicFilterPanel(
                        spec: spec,
                        initial: initial ?? spec.initial,
                        loadFacets: loader,
                        debounce: const Duration(milliseconds: 10),
                      ),
                    ),
                  ),
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump(); // dialog route
    await tester.pump(const Duration(milliseconds: 400)); // animation + load
  }

  /// Past the panel's debounce and the (instant) fake request.
  Future<void> settle(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 50));

  Finder apply() => find.descendant(
    of: find.byType(DynamicFilterPanel),
    matching: find.byType(ElevatedButton),
  );

  Finder reset() => find.descendant(
    of: find.byType(DynamicFilterPanel),
    matching: find.byType(OutlinedButton),
  );

  testWidgets('asks the server on open and shows what it returns', (
    tester,
  ) async {
    final calls = <CatalogFilters>[];
    await open(
      tester,
      loader: (draft) async {
        calls.add(draft);
        return facets(total: 120);
      },
    );

    expect(calls.single.inStockOnly, isTrue, reason: 'the shop default');
    // Counts beside every option, from the server.
    expect(find.text('Poem · 338'), findsOneWidget);
    expect(find.text('Thriller · 70'), findsOneWidget);
    expect(find.text('Bengali · 593'), findsOneWidget);
    expect(find.text('In stock only · 480'), findsOneWidget);
    expect(find.text('₹36 – ₹1485+'), findsOneWidget);
    // And the button says what Apply will give.
    expect(find.text('SHOW 120 BOOKS'), findsOneWidget);
  });

  testWidgets('picking an option re-asks the server with the new draft', (
    tester,
  ) async {
    final calls = <CatalogFilters>[];
    await open(
      tester,
      loader: (draft) async {
        calls.add(draft);
        // What picking Poem would leave.
        return draft.categories.isEmpty ? facets(total: 100) : facets(total: 7);
      },
    );
    expect(find.text('SHOW 100 BOOKS'), findsOneWidget);

    await tester.tap(find.text('Poem · 338'));
    await settle(tester);

    expect(calls, hasLength(2));
    expect(calls.last.categories, {poem});
    expect(find.text('SHOW 7 BOOKS'), findsOneWidget);
    // The other options stay listed — picking one doesn't hide its siblings.
    expect(find.text('Thriller · 70'), findsOneWidget);
    expect(find.text('Bengali · 593'), findsOneWidget);
  });

  testWidgets('a run of taps is one request, not one per tap', (tester) async {
    var calls = 0;
    await open(
      tester,
      loader: (draft) async {
        calls++;
        return facets();
      },
    );
    expect(calls, 1);

    await tester.tap(find.text('Poem · 338'));
    await tester.tap(find.text('Thriller · 70'));
    await tester.tap(find.text('Bengali · 593'));
    await settle(tester);

    expect(calls, 2, reason: 'initial load + one for all three taps');
  });

  testWidgets('a slow, older response never overwrites a newer one', (
    tester,
  ) async {
    final pending = <Completer<FilterFacets>>[];
    await open(
      tester,
      loader: (draft) {
        final completer = Completer<FilterFacets>();
        pending.add(completer);
        return completer.future;
      },
    );
    // Still waiting on the first answer: no options yet, just a spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending[0].complete(facets(total: 100));
    await tester.pump();

    // Two changes, so two more requests are in flight.
    await tester.tap(find.text('Poem · 338'));
    await settle(tester);
    await tester.tap(find.text('Thriller · 70'));
    await settle(tester);
    expect(pending, hasLength(3));

    // The newest answers first...
    pending[2].complete(facets(total: 3));
    await tester.pump();
    expect(find.text('SHOW 3 BOOKS'), findsOneWidget);

    // ...then the older one limps in. It describes a selection the user has
    // already moved on from, so it must be ignored.
    pending[1].complete(facets(total: 7));
    await tester.pump();
    expect(find.text('SHOW 3 BOOKS'), findsOneWidget);
    expect(find.text('SHOW 7 BOOKS'), findsNothing);
  });

  testWidgets('single-choice category: picking another replaces it', (
    tester,
  ) async {
    await open(
      tester,
      spec: ownerSpec,
      loader: (draft) async => facets(active: 10, inactive: 2),
    );

    await tester.tap(find.text('Poem · 338'));
    await settle(tester);
    await tester.tap(find.text('Thriller · 70'));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();

    expect(result?.categories, {thriller});
  });

  testWidgets('multi-choice category keeps both', (tester) async {
    await open(tester, loader: (draft) async => facets());

    await tester.tap(find.text('Poem · 338'));
    await settle(tester);
    await tester.tap(find.text('Thriller · 70'));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();

    expect(result?.categories, {poem, thriller});
  });

  testWidgets('tapping a picked option again clears it', (tester) async {
    await open(tester, loader: (draft) async => facets());

    await tester.tap(find.text('Bengali · 593'));
    await settle(tester);
    await tester.tap(find.text('Bengali · 593'));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();

    expect(result?.languages, isEmpty);
  });

  testWidgets('status shows counts and toggles', (tester) async {
    await open(
      tester,
      spec: ownerSpec,
      loader: (draft) async => facets(active: 515, inactive: 129),
    );

    expect(find.text('Active · 515'), findsOneWidget);
    expect(find.text('Inactive · 129'), findsOneWidget);

    await tester.tap(find.text('Inactive · 129'));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();

    expect(result?.isActive, isFalse);
  });

  testWidgets('the price slider takes its bounds from the server', (
    tester,
  ) async {
    final calls = <CatalogFilters>[];
    await open(
      tester,
      loader: (draft) async {
        calls.add(draft);
        return facets();
      },
    );

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.min, 36);
    expect(slider.max, 1485);

    // Pick ₹100–₹500, as dragging both thumbs would.
    slider.onChanged!(const RangeValues(100, 500));
    slider.onChangeEnd!(const RangeValues(100, 500));
    await tester.pump();
    expect(find.text('₹100 – ₹500'), findsOneWidget);
    await settle(tester);

    expect(calls.last.priceRange, (min: 100.0, max: 500.0));

    await tester.tap(apply());
    await tester.pumpAndSettle();
    expect(result?.priceRange, (min: 100.0, max: 500.0));
  });

  testWidgets('dragging back to the full range means no price filter', (
    tester,
  ) async {
    await open(tester, loader: (draft) async => facets());

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    slider.onChanged!(const RangeValues(100, 500));
    slider.onChanged!(const RangeValues(36, 1485));
    slider.onChangeEnd!(const RangeValues(36, 1485));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();

    expect(result?.priceRange, isNull);
  });

  testWidgets('no slider when every result costs the same', (tester) async {
    await open(
      tester,
      loader: (draft) async => facets(price: (min: 250, max: 250)),
    );

    expect(find.byType(RangeSlider), findsNothing);
    expect(find.text('No price range to choose from.'), findsOneWidget);
  });

  testWidgets('a selection with no results says so instead of going blank', (
    tester,
  ) async {
    await open(
      tester,
      loader: (draft) async => facets(
        total: 0,
        categories: const [],
        languages: const [],
        price: null,
      ),
    );

    expect(find.text('No categories for this selection.'), findsOneWidget);
    expect(find.text('No languages for this selection.'), findsOneWidget);
    expect(find.text('SHOW 0 BOOKS'), findsOneWidget);
  });

  testWidgets('a failed load says so, and Retry tries again', (tester) async {
    var attempts = 0;
    await open(
      tester,
      loader: (draft) async {
        attempts++;
        if (attempts == 1) throw const ApiFailure('Cannot reach the server.');
        return facets(total: 55);
      },
    );

    expect(find.text("Filter options couldn't be loaded."), findsOneWidget);
    expect(find.text('APPLY'), findsOneWidget, reason: 'no count to promise');

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text("Filter options couldn't be loaded."), findsNothing);
    expect(find.text('Poem · 338'), findsOneWidget);
    expect(find.text('SHOW 55 BOOKS'), findsOneWidget);
  });

  testWidgets('a long list is cut short, with Show all', (tester) async {
    final many = [
      for (var i = 1; i <= 15; i++)
        FacetOption(id: '$i', label: 'Cat $i', count: 20 - i),
    ];
    await open(tester, loader: (draft) async => facets(categories: many));

    expect(find.text('Cat 12 · 8'), findsOneWidget);
    expect(find.text('Cat 13 · 7'), findsNothing);
    expect(find.text('Show all 15'), findsOneWidget);

    await tester.tap(find.text('Show all 15'));
    await tester.pump();

    expect(find.text('Cat 15 · 5'), findsOneWidget);
    expect(find.text('Show all 15'), findsNothing);
  });

  testWidgets('a picked option the server no longer returns stays, to unpick', (
    tester,
  ) async {
    const retired = FacetOption(id: '77', label: 'Retired Shelf');
    await open(
      tester,
      initial: const CatalogFilters(inStockOnly: true)
          .copyWith(categories: {retired}),
      loader: (draft) async => facets(),
    );

    // Listed first, with no count (the server says nothing about it).
    expect(find.text('Retired Shelf'), findsOneWidget);

    await tester.tap(find.text('Retired Shelf'));
    await settle(tester);
    await tester.tap(apply());
    await tester.pumpAndSettle();
    expect(result?.categories, isEmpty);
  });

  testWidgets('RESET goes back to the screen\'s start, and asks again', (
    tester,
  ) async {
    final calls = <CatalogFilters>[];
    await open(
      tester,
      initial: const CatalogFilters(), // user had switched the default off
      loader: (draft) async {
        calls.add(draft);
        return facets();
      },
    );
    expect(tester.widget<OutlinedButton>(reset()).onPressed, isNotNull);

    await tester.tap(reset());
    await tester.pump();
    await settle(tester);

    expect(calls.last.inStockOnly, isTrue, reason: 'the shop default again');
    expect(tester.widget<OutlinedButton>(reset()).onPressed, isNull);
  });

  testWidgets('dismissing without Apply changes nothing', (tester) async {
    await open(tester, loader: (draft) async => facets());

    await tester.tap(find.text('Poem · 338'));
    await settle(tester);
    // Tap outside the dialog.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, isNull);
  });
}

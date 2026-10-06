import 'package:flutter_test/flutter_test.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';

const poem = FacetOption(id: '1001', label: 'Poem', count: 338);
const thriller = FacetOption(id: '1004', label: 'Thriller', count: 70);
const bengali = FacetOption(id: 'Bengali', label: 'Bengali', count: 593);

void main() {
  group('CatalogFilters.toQuery', () {
    test('sends nothing for the empty selection', () {
      expect(
        const CatalogFilters().toQuery(categoryKey: 'category'),
        isEmpty,
        reason: 'the API rejects empty values, so unset fields are omitted',
      );
    });

    test('maps each field to the key the screen passes', () {
      final query = CatalogFilters(
        isActive: false,
        inStockOnly: true,
        categories: {poem},
        languages: {bengali},
        priceRange: (min: 99.6, max: 200.2),
      ).toQuery(categoryKey: 'category_id', statusKey: 'is_active');

      expect(query, {
        'is_active': 0,
        'in_stock': 1,
        'category_id': '1001',
        'language': 'Bengali',
        'min_price': 99, // floor — never exclude the lower bound
        'max_price': 201, // ceil — never exclude the upper bound
      });
    });

    test('joins several options with commas, in a stable order', () {
      final query = CatalogFilters(categories: {thriller, poem})
          .toQuery(categoryKey: 'category');

      expect(query['category'], '1001,1004');
    });

    test('leaves out fields a screen does not have', () {
      final query =
          CatalogFilters(
            isActive: true,
            languages: {bengali},
            priceRange: (min: 1, max: 2),
          ).toQuery(
            categoryKey: 'category',
            includeLanguages: false,
            includePrice: false,
          );

      expect(query.containsKey('language'), isFalse);
      expect(query.containsKey('min_price'), isFalse);
      expect(
        query.containsKey('status'),
        isFalse,
        reason: 'no statusKey given',
      );
    });
  });

  group('CatalogFilters.activeCount', () {
    const none = CatalogFilters();

    test('counts groups, not options', () {
      expect(none.activeCount(none), 0);
      expect(CatalogFilters(categories: {poem, thriller}).activeCount(none), 1);
      expect(
        CatalogFilters(
          isActive: true,
          inStockOnly: true,
          categories: {poem},
          languages: {bengali},
          priceRange: (min: 1, max: 2),
        ).activeCount(none),
        5,
      );
    });

    test('is measured against the screen\'s own starting point', () {
      const shopStart = CatalogFilters(inStockOnly: true);

      expect(
        shopStart.activeCount(shopStart),
        0,
        reason: 'the default is free',
      );
      expect(
        const CatalogFilters().activeCount(shopStart),
        1,
        reason: 'turning the default off is a change',
      );
      expect(shopStart.isInitial(shopStart), isTrue);
    });
  });

  group('FacetOption', () {
    test('is the same option whatever its count', () {
      expect(
        const FacetOption(id: '1', label: 'A', count: 5),
        const FacetOption(id: '1', label: 'A', count: 0),
      );
    });
  });

  group('FilterFacets.fromJson', () {
    test('parses a full shop response', () {
      final facets = FilterFacets.fromJson({
        'total': 593,
        'categories': [
          {'id': 1001, 'name': ' Poem ', 'count': 338},
        ],
        'languages': [
          {'value': 'Bengali', 'count': '593'},
        ],
        'price': {'min': 36, 'max': 1485},
        'stock': {'in_stock': 480},
      });

      expect(facets.total, 593);
      expect(facets.categories.single.id, '1001');
      expect(facets.categories.single.label, 'Poem'); // trimmed
      expect(facets.categories.single.count, 338);
      expect(facets.languages.single.id, 'Bengali');
      expect(facets.languages.single.label, 'Bengali');
      expect(facets.languages.single.count, 593); // "593" coerced
      expect(facets.price, (min: 36.0, max: 1485.0));
      expect(facets.inStock, 480);
      expect(facets.hasStatus, isFalse);
    });

    test('reads the owner screens\' status counts', () {
      final facets = FilterFacets.fromJson({
        'total': 650,
        'categories': <Object>[],
        'stock': {'in_stock': 449},
        'status': {'active': 515, 'inactive': 129},
      });

      expect(facets.hasStatus, isTrue);
      expect(facets.active, 515);
      expect(facets.inactive, 129);
      expect(facets.price, isNull, reason: 'owner screens have no price facet');
    });

    test('survives missing and malformed parts', () {
      final facets = FilterFacets.fromJson({
        'categories': [
          {'id': null, 'name': 'No id'},
          'not an object',
          {'id': 7}, // no name: falls back to the id
        ],
        'price': null,
      });

      expect(facets.total, 0);
      expect(facets.categories.map((c) => c.id), ['7']);
      expect(facets.categories.single.label, '7');
      expect(facets.price, isNull);
      expect(facets.inStock, 0);
    });
  });
}

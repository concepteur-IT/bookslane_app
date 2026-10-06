import 'package:flutter_test/flutter_test.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:bookslane_app/features/shop/data/repositories/shop_repository_impl.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:dio/dio.dart';

import '../products/products_repository_test.dart'
    show FakeAdapter, FakeTokenStorage;

Map<String, dynamic> row({
  Object? id = 'publishing-3244',
  String source = 'publishing',
  int refId = 3244,
  String name = 'Baitalik',
  Object? price = 250,
  Object? sellingPrice = 200,
  Object? stock = 12,
  Object? isActive = 1,
  Object? imageUrl =
      'https://thinkerslane.com/public/uploads/admin/books/a.jpg',
}) => {
  'id': id,
  'source': source,
  'ref_id': refId,
  'name': name,
  'author': 'Rabindranath Tagore',
  'code': 'TL-3244',
  'image_url': imageUrl,
  'price': price,
  'selling_price': sellingPrice,
  'stock': stock,
  'in_stock': true,
  'is_active': isActive,
  'language': 'Bengali',
  'created_at': '2026-09-01T00:00:00.000Z',
};

Map<String, dynamic> listBody(
  List<Map<String, dynamic>> rows, {
  int total = 1,
  int page = 1,
  int totalPages = 1,
  bool hasNext = false,
}) => {
  'data': rows,
  'pagination': {
    'page': page,
    'limit': 20,
    'total': total,
    'total_pages': totalPages,
    'has_next': hasNext,
  },
};

void main() {
  ({ShopRepositoryImpl repo, FakeAdapter adapter}) build(
    ({int status, Map<String, dynamic> body}) Function(RequestOptions) respond,
  ) {
    final adapter = FakeAdapter(respond);
    final api = ApiClient(
      config: AppConfig.current.copyWith(enableLogging: false),
      storage: FakeTokenStorage(),
    );
    api.dio.httpClientAdapter = adapter;
    return (
      repo: ShopRepositoryImpl(
        remoteDataSource: ShopRemoteDataSource(apiClient: api),
      ),
      adapter: adapter,
    );
  }

  group('fetchBooks', () {
    test('parses the catalogue rows', () async {
      final t = build((_) => (status: 200, body: listBody([row()], total: 1)));

      final page = await t.repo.fetchBooks(page: 1);

      final book = page.items.single;
      expect(book.id, 'publishing-3244');
      expect(book.source, ShopSource.publishing);
      expect(book.refId, 3244);
      expect(book.title, 'Baitalik');
      expect(book.author, 'Rabindranath Tagore');
      expect(book.sku, 'TL-3244');
      expect(book.mrp, 250);
      expect(book.price, 200, reason: 'the selling price, not the MRP');
      expect(book.isDiscounted, isTrue);
      expect(book.isSoldOut, isFalse);
      expect(book.imageUrl, endsWith('a.jpg'));
      expect(page.total, 1);
      expect(page.hasNext, isFalse);
    });

    test('tells the two shelves apart, and their ids never collide', () async {
      final t = build(
        (_) => (
          status: 200,
          body: listBody([
            row(), // product 3244
            row(
              id: 'store-3244',
              source: 'store',
              refId: 3244, // the same number, a different book
              name: 'My Own Book',
            ),
          ]),
        ),
      );

      final books = (await t.repo.fetchBooks(page: 1)).items;

      expect(books.map((b) => b.source), [
        ShopSource.publishing,
        ShopSource.store,
      ]);
      expect(books.map((b) => b.id).toSet(), hasLength(2));
      expect(books.last.title, 'My Own Book');
    });

    test('an old server\'s bare numeric id still makes a usable row', () async {
      final t = build(
        (_) => (status: 200, body: listBody([row(id: null, refId: 7)])),
      );

      final book = (await t.repo.fetchBooks(page: 1)).items.single;

      expect(book.id, 'publishing-7');
      expect(book.refId, 7);
    });

    test('tolerates numbers sent as strings, and blank images', () async {
      final t = build(
        (_) => (
          status: 200,
          body: listBody([
            row(price: '120.50', sellingPrice: '99', stock: '0', imageUrl: ''),
          ]),
        ),
      );

      final book = (await t.repo.fetchBooks(page: 1)).items.single;

      expect(book.mrp, 120.5);
      expect(book.price, 99);
      expect(book.isSoldOut, isTrue);
      expect(book.imageUrl, isNull);
    });

    test('falls back to the list price when no selling price comes', () async {
      final t = build(
        (_) => (status: 200, body: listBody([row(sellingPrice: null)])),
      );

      final book = (await t.repo.fetchBooks(page: 1)).items.single;

      expect(book.price, 250);
      expect(book.isDiscounted, isFalse);
    });

    test('reads the pagination block', () async {
      final t = build(
        (_) => (
          status: 200,
          body: listBody(
            [row()],
            total: 6309,
            page: 2,
            totalPages: 316,
            hasNext: true,
          ),
        ),
      );

      final page = await t.repo.fetchBooks(page: 2);

      expect(page.total, 6309);
      expect(page.page, 2);
      expect(page.totalPages, 316);
      expect(page.hasNext, isTrue);
    });

    test(
      'sends paging, sort and search; nothing else when unfiltered',
      () async {
        final t = build((_) => (status: 200, body: listBody([])));

        await t.repo.fetchBooks(page: 3, limit: 20, search: '  tagore ');

        expect(t.adapter.requests.single.queryParameters, {
          'page': 3,
          'limit': 20,
          'sort': 'featured',
          'search': 'tagore',
        });
      },
    );

    test('sends every filter the shop has, in the API\'s terms', () async {
      final t = build((_) => (status: 200, body: listBody([])));

      await t.repo.fetchBooks(
        page: 1,
        sort: ShopSort.priceLow,
        filters: CatalogFilters(
          inStockOnly: true,
          categories: {
            const FacetOption(id: '1004', label: 'Thriller'),
            const FacetOption(id: '1001', label: 'Poem'),
          },
          languages: {const FacetOption(id: 'Bengali', label: 'Bengali')},
          priceRange: (min: 99.6, max: 200.2),
        ),
      );

      final query = t.adapter.requests.single.queryParameters;
      expect(query['sort'], 'price_low');
      expect(query['in_stock'], 1);
      expect(query['category'], '1001,1004');
      expect(query['language'], 'Bengali');
      expect(query['min_price'], 99);
      expect(query['max_price'], 201);
      expect(
        query.containsKey('status'),
        isFalse,
        reason: 'no status in the shop',
      );
      expect(query.containsKey('is_active'), isFalse);
    });

    test('the status filter goes as is_active', () async {
      final t = build((_) => (status: 200, body: listBody([])));

      await t.repo.fetchBooks(
        page: 1,
        filters: CatalogFilters(isActive: false),
      );

      expect(t.adapter.requests.single.queryParameters['is_active'], 0);
    });

    test(
      'carries each book\'s active flag; an old server\'s absence means active',
      () async {
        final t = build(
          (_) => (
            status: 200,
            body: listBody([
              row(id: 'publishing-1', isActive: 0),
              row(id: 'publishing-2', isActive: 1),
              row(id: 'publishing-3', isActive: null),
            ]),
          ),
        );

        final books = (await t.repo.fetchBooks(page: 1)).items;

        expect(books.map((b) => b.isActive), [false, true, true]);
      },
    );

    test('every sort sends the key app-api accepts', () async {
      const accepted = {
        'featured', 'newest', 'oldest', 'price_low', 'price_high', 'title',
        'title_desc', //
      };
      expect(ShopSort.values.map((s) => s.value).toSet(), accepted);
    });

    test('a malformed body becomes an ApiFailure, not a crash', () async {
      final t = build((_) => (status: 200, body: {'oops': true}));

      expect(t.repo.fetchBooks(page: 1), throwsA(isA<ApiFailure>()));
    });
  });

  group('fetchFilters', () {
    test('asks /shop/filters with the list\'s filter params', () async {
      final t = build(
        (_) => (
          status: 200,
          body: {
            'total': 593,
            'categories': [
              {'id': 1001, 'name': 'Poem', 'count': 338},
            ],
            'languages': [
              {'value': 'Bengali', 'count': 593},
              {'value': 'English', 'count': 42},
            ],
            'price': {'min': 36, 'max': 1485},
            'stock': {'in_stock': 480},
          },
        ),
      );

      final facets = await t.repo.fetchFilters(
        CatalogFilters(
          inStockOnly: true,
          languages: {const FacetOption(id: 'Bengali', label: 'Bengali')},
        ),
        search: 'tagore',
      );

      final request = t.adapter.requests.single;
      expect(request.path, endsWith('/shop/filters'));
      // No paging or sort: the endpoint rejects them.
      expect(request.queryParameters, {
        'search': 'tagore',
        'in_stock': 1,
        'language': 'Bengali',
      });
      expect(facets.total, 593);
      expect(facets.categories.single.label, 'Poem');
      expect(facets.languages.map((l) => l.label), ['Bengali', 'English']);
      expect(facets.price, (min: 36.0, max: 1485.0));
      expect(facets.inStock, 480);
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/data/datasources/books_remote_datasource.dart';
import 'package:bookslane_app/features/books/data/models/book_model.dart';
import 'package:bookslane_app/features/books/data/repositories/books_repository_impl.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/providers/books_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_categories.dart';

import '../products/products_repository_test.dart'
    show FakeAdapter, FakeTokenStorage;

/// The My Store filter and sort overlays only work if each choice reaches
/// `GET /v1/books` as the query param app-api expects.
void main() {
  panelStateTests();

  ({BooksRepositoryImpl repo, FakeAdapter adapter}) build({
    ({int status, Map<String, dynamic> body}) Function(RequestOptions)? respond,
  }) {
    final adapter = FakeAdapter(
      respond ??
          (_) => (
            status: 200,
            body: {
              'data': <Object>[],
              'pagination': {
                'page': 1,
                'limit': 10,
                'total': 0,
                'total_pages': 0,
                'has_next': false,
              },
            },
          ),
    );
    final api = ApiClient(
      config: AppConfig.current.copyWith(enableLogging: false),
      storage: FakeTokenStorage(),
    );
    api.dio.httpClientAdapter = adapter;
    return (
      repo: BooksRepositoryImpl(
        remoteDataSource: BooksRemoteDataSource(apiClient: api),
      ),
      adapter: adapter,
    );
  }

  test('the initial filters send no filter params at all', () async {
    final t = build();

    await t.repo.fetchBooks(page: 1);

    final query = t.adapter.requests.single.queryParameters;
    expect(query.containsKey('status'), isFalse);
    expect(query.containsKey('in_stock'), isFalse);
    expect(query.containsKey('category'), isFalse);
    expect(query['sort'], 'created_at');
    expect(query['order'], 'DESC');
  });

  test('status, stock and category each map to their param', () async {
    final t = build();

    await t.repo.fetchBooks(
      page: 1,
      filters: CatalogFilters(
        isActive: false,
        inStockOnly: true,
        categories: {testPoemFacet},
      ),
    );

    final query = t.adapter.requests.single.queryParameters;
    expect(query['status'], 0);
    expect(query['in_stock'], 1);
    expect(query['category'], '${testPoem.id}');
    expect(query.containsKey('language'), isFalse);
    expect(query.containsKey('min_price'), isFalse);
  });

  test('the filter panel\'s options come from /books/filters', () async {
    final t = build(
      respond: (_) => (
        status: 200,
        body: {
          'total': 2,
          'categories': [
            {'id': 1001, 'name': 'Poem', 'count': 1},
          ],
          'stock': {'in_stock': 2},
          'status': {'active': 2, 'inactive': 0},
        },
      ),
    );

    // Takes the very params the list takes — that's what makes "SHOW N" true.
    final facets = await t.repo.fetchFilters(
      CatalogFilters(isActive: true, categories: {testNonFictionFacet}),
      search: '  guide ',
    );

    final request = t.adapter.requests.single;
    expect(request.path, endsWith('/books/filters'));
    expect(request.queryParameters, {
      'search': 'guide',
      'status': 1,
      'category': '${testNonFiction.id}',
    });
    expect(facets.total, 2);
    expect(facets.categories.single.label, 'Poem');
    expect(facets.active, 2);
  });

  test('every sort maps to a field app-api accepts', () async {
    const expected = {
      BookSort.newest: ('created_at', 'DESC'),
      BookSort.oldest: ('created_at', 'ASC'),
      BookSort.priceLow: ('price', 'ASC'),
      BookSort.priceHigh: ('price', 'DESC'),
      BookSort.title: ('title', 'ASC'),
      BookSort.titleDesc: ('title', 'DESC'),
    };
    expect(expected.keys, containsAll(BookSort.values));

    for (final MapEntry(key: sort, value: (field, order)) in expected.entries) {
      final t = build();
      await t.repo.fetchBooks(page: 1, sort: sort);

      final query = t.adapter.requests.single.queryParameters;
      expect(query['sort'], field, reason: '$sort');
      expect(query['order'], order, reason: '$sort');
    }
  });

  test('parses the form\'s category list from /categories', () async {
    final t = build(
      respond: (_) => (
        status: 200,
        body: {
          'data': [
            {'id': 1001, 'name': ' Poem '},
            {'id': '986', 'name': 'অঞ্চলচর্চা গ্রন্থমালা'},
          ],
        },
      ),
    );

    final categories = await t.repo.fetchCategories();

    expect(t.adapter.requests.single.path, endsWith('/categories'));
    expect(categories.map((c) => c.id), [1001, 986]); // "986" coerced
    expect(categories.first.name, 'Poem'); // trimmed
    expect(categories.last.name, 'অঞ্চলচর্চা গ্রন্থমালা');
  });

  test('a book carries its category only when the API names it', () async {
    Map<String, dynamic> row(Object? category, Object? name) => {
      'id': 1,
      'name': 'The Guide',
      'author': 'R. K. Narayan',
      'category': category,
      'category_name': name,
      'language': 'en',
      'binding': 'paperback',
      'discount_type': 'flat',
      'price': 100,
      'quantity': 1,
      'is_active': 1,
    };

    BookCategory? categoryOf(Map<String, dynamic> json) =>
        BookModel.fromJson(json).toDetail().category;

    expect(
      categoryOf(row('1001', 'Poem')),
      const BookCategory(id: 1001, name: 'Poem'),
    );
    // A stale id from before the shared table (no name) reads as no category.
    expect(categoryOf(row('1', null)), isNull);
    expect(categoryOf(row(null, null)), isNull);
  });

  test('the filter badge counts only what differs from the default', () {
    expect(const CatalogFilters().activeCount(const CatalogFilters()), 0);
    expect(
      CatalogFilters(
        isActive: true,
        categories: {testNonFictionFacet},
      ).activeCount(BooksProvider.filterSpec.initial),
      2,
    );
  });

  testWidgets('the overlays refetch with what was picked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingBooks();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Provider<BooksRepository>.value(
          value: repository,
          child: const BookListPage(source: BookSource.store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.reads.single.filters.isInitial(_start), isTrue);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    // Wide as the toolbar — regression: a panel of only chips and switches
    // used to collapse to a sliver.
    expect(
      tester.getSize(find.byType(FilterPanelFrame)).width,
      tester.getSize(find.byType(ListToolbar)).width,
    );

    // The options are the server's, with counts.
    expect(find.text('Active · 5'), findsOneWidget);
    expect(find.text('Poem · 3'), findsOneWidget);

    await tester.tap(find.text('Inactive · 1'));
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Poem · 3'));
    await tester.pumpAndSettle();

    // Every change re-asked the server what the selection leaves.
    final asked = repository.facetReads.last;
    expect(asked.isActive, isFalse);
    expect(asked.inStockOnly, isTrue);
    expect(asked.categories, {testPoemFacet});
    expect(repository.facetReads.last.categories, isNotEmpty);

    // …and Apply says how many books it will show.
    await tester.tap(find.text('SHOW 4 BOOKS'));
    await tester.pumpAndSettle();

    final filtered = repository.reads.last.filters;
    expect(filtered.isActive, isFalse);
    expect(filtered.inStockOnly, isTrue);
    expect(filtered.categories, {testPoemFacet});
    expect(find.text('3'), findsOneWidget); // the filter badge

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title: Z to A'));
    await tester.pumpAndSettle();

    expect(repository.reads.last.sort, BookSort.titleDesc);
    expect(repository.reads.last.filters.categories, {
      testPoemFacet,
    }, reason: 'sorting keeps the filters');
  });

  testWidgets('the panel counts books for the current search', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingBooks();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Provider<BooksRepository>.value(
          value: repository,
          child: const BookListPage(source: BookSource.store),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(AppSearchField), 'guide');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    expect(repository.searchesAsked.last, 'guide');
  });
}

/// What the panel says when the server has no options, or can't be reached.
void panelStateTests() {
  testWidgets('no categories for the selection says so', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingBooks()..facetMode = _FacetMode.empty;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Provider<BooksRepository>.value(
          value: repository,
          child: const BookListPage(source: BookSource.store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    expect(find.text('No categories for this selection.'), findsOneWidget);
  });

  testWidgets('a failed options load says so, with Retry', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RecordingBooks()..facetMode = _FacetMode.fail;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Provider<BooksRepository>.value(
          value: repository,
          child: const BookListPage(source: BookSource.store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    expect(find.text("Filter options couldn't be loaded."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

enum _FacetMode { normal, empty, fail }

/// What My Store opens with: no filters at all.
const _start = CatalogFilters();

/// Records every list query and every filter-options request.
class _RecordingBooks implements BooksRepository {
  final List<({CatalogFilters filters, BookSort sort})> reads = [];

  /// The draft each `/filters` request was made for.
  final List<CatalogFilters> facetReads = [];
  final List<String?> searchesAsked = [];

  _FacetMode facetMode = _FacetMode.normal;

  @override
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    BookSort sort = BookSort.initial,
  }) async {
    reads.add((filters: filters, sort: sort));
    return BookPage(
      items: const [],
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
      hasNext: false,
    );
  }

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async {
    facetReads.add(filters);
    searchesAsked.add(search);

    switch (facetMode) {
      case _FacetMode.fail:
        throw const ApiFailure('Cannot reach the server.');
      case _FacetMode.empty:
        return const FilterFacets(total: 0, active: 0, inactive: 0);
      case _FacetMode.normal:
        // Each pick narrows the total, so the button's count visibly follows
        // the draft: 6 books, minus one per filter group chosen.
        return FilterFacets(
          total: 7 - filters.activeCount(_start),
          categories: const [
            FacetOption(id: '1001', label: 'Poem', count: 3),
            FacetOption(id: '1018', label: 'Non-fiction', count: 2),
          ],
          inStock: 6,
          active: 5,
          inactive: 1,
        );
    }
  }

  @override
  Future<List<BookCategory>> fetchCategories() async => testCategories;

  @override
  Future<BookDetail> getBook(String id) => throw UnimplementedError();
  @override
  Future<Book> createBook(BookDraft draft) => throw UnimplementedError();
  @override
  Future<Book> updateBook(String id, BookDraft draft) =>
      throw UnimplementedError();
  @override
  Future<Book> setActive({required String id, required bool isActive}) =>
      throw UnimplementedError();
}

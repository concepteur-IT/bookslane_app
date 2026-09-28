import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/data/datasources/books_remote_datasource.dart';
import 'package:bookslane_app/features/books/data/repositories/books_repository_impl.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../products/products_repository_test.dart'
    show FakeAdapter, FakeTokenStorage;

/// The My Store filter and sort overlays only work if each choice reaches
/// `GET /v1/books` as the query param app-api expects.
void main() {
  ({BooksRepositoryImpl repo, FakeAdapter adapter}) build() {
    final adapter = FakeAdapter(
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
      filters: const BookFilters(
        isActive: false,
        inStockOnly: true,
        category: BookCategory.poetry,
      ),
    );

    final query = t.adapter.requests.single.queryParameters;
    expect(query['status'], 0);
    expect(query['in_stock'], 1);
    expect(query['category'], '${BookCategory.poetry.id}');
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

  test('the filter badge counts only what differs from the default', () {
    expect(BookFilters.initial.activeCount, 0);
    expect(
      const BookFilters(
        isActive: true,
        category: BookCategory.fiction,
      ).activeCount,
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
    expect(repository.reads.single.filters.isInitial, isTrue);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    // Wide as the toolbar — regression: a panel of only chips and switches
    // used to collapse to a sliver.
    expect(
      tester.getSize(find.byType(FilterPanelFrame)).width,
      tester.getSize(find.byType(ListToolbar)).width,
    );
    await tester.tap(find.text('Inactive'));
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Poetry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poetry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APPLY'));
    await tester.pumpAndSettle();

    final filtered = repository.reads.last.filters;
    expect(filtered.isActive, isFalse);
    expect(filtered.inStockOnly, isTrue);
    expect(filtered.category, BookCategory.poetry);
    expect(find.text('3'), findsOneWidget); // the filter badge

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title: Z to A'));
    await tester.pumpAndSettle();

    expect(repository.reads.last.sort, BookSort.titleDesc);
    expect(
      repository.reads.last.filters.category,
      BookCategory.poetry,
      reason: 'sorting keeps the filters',
    );
  });
}

/// Records every list query; returns an empty page.
class _RecordingBooks implements BooksRepository {
  final List<({BookFilters filters, BookSort sort})> reads = [];

  @override
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    BookFilters filters = BookFilters.initial,
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

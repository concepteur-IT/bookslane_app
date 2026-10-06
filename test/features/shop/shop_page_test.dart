import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/domain/repositories/shop_repository.dart';
import 'package:bookslane_app/features/shop/presentation/pages/shop_page.dart';
import 'package:bookslane_app/features/shop/presentation/providers/shop_provider.dart';

const _inStock = ShopBook(
  id: 'publishing-1',
  source: ShopSource.publishing,
  refId: 1,
  title: 'Baitalik',
  author: 'Rabindranath Tagore',
  sku: 'TL-3244',
  mrp: 250,
  price: 200,
  stock: 12,
);

const _soldOut = ShopBook(
  id: 'publishing-2',
  source: ShopSource.publishing,
  refId: 2,
  title: 'Aranyak',
  author: 'Bibhutibhushan',
  sku: 'TL-1120',
  mrp: 350,
  price: 350,
  stock: 0,
);

/// Switched off by its owner — the Shop still lists it, tagged.
const _inactive = ShopBook(
  id: 'publishing-3',
  source: ShopSource.publishing,
  refId: 3,
  title: 'Draft Poems',
  author: 'Me',
  sku: 'TL-0003',
  mrp: 60,
  price: 60,
  stock: 2,
  isActive: false,
);

/// A book the account sells itself — it sits beside the publishings.
const _storeBook = ShopBook(
  id: 'store-1',
  source: ShopSource.store,
  refId: 1,
  title: 'My Own Poems',
  author: 'Me',
  sku: 'BL-0001',
  mrp: 120,
  price: 99,
  stock: 4,
);

const _poem = FacetOption(id: '1001', label: 'Poem');
const _bengali = FacetOption(id: 'Bengali', label: 'Bengali');

/// Stands in for `/v1/shop` — records every query, and answers filter
/// requests the way the server does: a total that follows the draft.
class FakeShopRepository implements ShopRepository {
  FakeShopRepository({this.books = const [_inStock, _soldOut]});

  List<ShopBook> books;
  ApiFailure? failure;
  int totalPages = 1;

  final List<
    ({int page, String? search, CatalogFilters filters, ShopSort sort})
  >
  reads = [];
  final List<CatalogFilters> facetReads = [];

  @override
  Future<ShopBookPage> fetchBooks({
    required int page,
    int limit = 20,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ShopSort sort = ShopSort.initial,
  }) async {
    reads.add((page: page, search: search, filters: filters, sort: sort));
    if (failure != null) throw failure!;
    return ShopBookPage(
      items: books,
      page: page,
      limit: limit,
      total: books.length * totalPages,
      totalPages: totalPages,
      hasNext: page < totalPages,
    );
  }

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async {
    facetReads.add(filters);
    return FilterFacets(
      total: 40 - filters.categories.length * 10 - filters.languages.length * 5,
      categories: const [
        FacetOption(id: '1001', label: 'Poem', count: 338),
        FacetOption(id: '1004', label: 'Thriller', count: 70),
      ],
      languages: const [
        FacetOption(id: 'Bengali', label: 'Bengali', count: 593),
        FacetOption(id: 'English', label: 'English', count: 42),
      ],
      price: (min: 36, max: 1485),
      inStock: 480,
      active: 108,
      inactive: 4,
    );
  }
}

void main() {
  late CartProvider cart;

  setUp(() => cart = CartProvider());

  Future<void> pumpShop(
    WidgetTester tester,
    FakeShopRepository repository,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ShopRepository>.value(value: repository),
          ChangeNotifierProvider<CartProvider>.value(value: cart),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ShopPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inPanel(String text) => find.descendant(
    of: find.byType(FilterPanelFrame),
    matching: find.text(text),
  );

  testWidgets('opens with no filter on, so nothing is hidden', (tester) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    final read = repository.reads.single;
    expect(read.page, 1);
    expect(read.sort, ShopSort.featured);
    // The Shop must list what My Publishings and My Store list together. A
    // starting filter (it used to be "in stock only") hides books silently —
    // and for one real account that was 104 of 112.
    expect(read.filters.isInitial(ShopProvider.filterSpec.initial), isTrue);
    expect(read.filters.inStockOnly, isFalse);
    expect(read.filters.isActive, isNull);

    expect(find.text('₹200.00'), findsOneWidget); // selling price…
    expect(find.text('₹250.00'), findsOneWidget); // …beside the struck-out MRP
    expect(find.text('Sold out'), findsOneWidget, reason: 'sold-out is listed');
    expect(find.text('TL-3244'), findsOneWidget);
  });

  testWidgets('inactive books are listed, and tagged', (tester) async {
    await pumpShop(
      tester,
      FakeShopRepository(books: const [_inStock, _inactive]),
    );

    expect(find.text('Draft Poems'), findsWidgets);
    expect(find.text('Inactive'), findsOneWidget);
  });

  testWidgets('shows publishings and store books together, labelled', (
    tester,
  ) async {
    final repository = FakeShopRepository(
      books: const [_inStock, _storeBook, _soldOut],
    );
    await pumpShop(tester, repository);

    // One list, one request — both shelves come back from the same endpoint.
    expect(repository.reads, hasLength(1));
    expect(find.text('₹200.00'), findsOneWidget); // a publishing
    expect(find.text('₹99.00'), findsOneWidget); // a store book

    // Each card says which shelf it is from.
    expect(find.text('Publishing'), findsNWidgets(2));
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('BL-0001'), findsOneWidget);
  });

  testWidgets('choosing a filter shows on the badge', (tester) async {
    await pumpShop(tester, FakeShopRepository());
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch)); // In stock only
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('SHOW'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Status is a filter, with counts, not a hidden rule', (
    tester,
  ) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    expect(inPanel('Active · 108'), findsOneWidget);
    expect(inPanel('Inactive · 4'), findsOneWidget);

    await tester.tap(inPanel('Inactive · 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('SHOW'));
    await tester.pumpAndSettle();

    expect(repository.reads.last.filters.isActive, isFalse);
  });

  testWidgets('the panel\'s options are the server\'s, and apply refetches', (
    tester,
  ) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    // Everything below came from /shop/filters, none of it from the app.
    expect(inPanel('Poem · 338'), findsOneWidget);
    expect(inPanel('Bengali · 593'), findsOneWidget);
    expect(inPanel('English · 42'), findsOneWidget);
    expect(inPanel('In stock only · 480'), findsOneWidget);
    expect(find.byType(RangeSlider), findsOneWidget);
    expect(inPanel('SHOW 40 BOOKS'), findsOneWidget);

    await tester.tap(inPanel('Poem · 338'));
    await tester.tap(inPanel('Bengali · 593'));
    await tester.pumpAndSettle();

    // The server was asked about the draft, and the button follows the answer.
    expect(repository.facetReads.last.categories, {_poem});
    expect(repository.facetReads.last.languages, {_bengali});
    expect(inPanel('SHOW 25 BOOKS'), findsOneWidget);

    await tester.tap(inPanel('SHOW 25 BOOKS'));
    await tester.pumpAndSettle();

    final filters = repository.reads.last.filters;
    expect(filters.categories, {_poem});
    expect(filters.languages, {_bengali});
    expect(filters.inStockOnly, isFalse, reason: 'not asked for');
    expect(repository.reads.last.page, 1);
    expect(find.text('2'), findsOneWidget); // category + language
  });

  testWidgets('search refetches from page one', (tester) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    await tester.enterText(find.byType(AppSearchField), 'tagore');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.reads.last.search, 'tagore');
    expect(repository.reads.last.page, 1);
  });

  testWidgets('the sort overlay sorts on the server, and Clear resets it', (
    tester,
  ) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: low to high'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.sort, ShopSort.priceLow);

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLEAR'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.sort, ShopSort.featured);
  });

  testWidgets('pages forward and back', (tester) async {
    final repository = FakeShopRepository()..totalPages = 3;
    await pumpShop(tester, repository);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.page, 2);
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous page'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.page, 1);
  });

  testWidgets('a selection with no books shows the empty state', (
    tester,
  ) async {
    final repository = FakeShopRepository(books: const []);
    await pumpShop(tester, repository);

    expect(find.text('No books match that.'), findsOneWidget);
    expect(
      find.text('CLEAR FILTERS'),
      findsNothing,
      reason: 'no filter is on — nothing to clear',
    );
  });

  testWidgets('CLEAR FILTERS goes back to the shop\'s starting point', (
    tester,
  ) async {
    final repository = FakeShopRepository();
    await pumpShop(tester, repository);

    // Pick a category, then get a result with nothing in it.
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(inPanel('Poem · 338'));
    await tester.pumpAndSettle();
    repository.books = const [];
    await tester.tap(find.textContaining('SHOW'));
    await tester.pumpAndSettle();

    expect(find.text('No books match that.'), findsOneWidget);
    repository.books = const [_inStock];
    await tester.tap(find.text('CLEAR FILTERS'));
    await tester.pumpAndSettle();

    expect(repository.reads.last.filters.categories, isEmpty);
    expect(repository.reads.last.filters.inStockOnly, isFalse);
    expect(find.text('Baitalik'), findsWidgets);
  });

  testWidgets('a failed load shows the message, and TRY AGAIN retries', (
    tester,
  ) async {
    final repository = FakeShopRepository()
      ..failure = const ApiFailure('Cannot reach the server.');
    await pumpShop(tester, repository);

    expect(find.text('Cannot reach the server.'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot reach the server.'), findsNothing);
    expect(find.text('₹200.00'), findsOneWidget);
  });

  testWidgets('the add button is a +, not a bag', (tester) async {
    await pumpShop(tester, FakeShopRepository(books: const [_inStock]));

    final add = find.descendant(
      of: find.byTooltip('Add to cart'),
      matching: find.byType(Icon),
    );
    expect(tester.widget<Icon>(add).icon, Icons.add_rounded);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
  });

  testWidgets('Add to cart puts the book in the cart and says so', (
    tester,
  ) async {
    await pumpShop(tester, FakeShopRepository(books: const [_inStock]));

    await tester.tap(find.byTooltip('Add to cart'));
    await tester.pump();

    expect(find.text('Baitalik added to cart.'), findsOneWidget);
    expect(cart.count, 1);
    expect(cart.quantityOf(_inStock), 1);
    // Let the toast time out so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tapping + again adds another, up to what is in stock', (
    tester,
  ) async {
    const scarce = ShopBook(
      id: 'store-9',
      source: ShopSource.store,
      refId: 9,
      title: 'Last Two',
      author: 'Me',
      sku: 'BL-9',
      mrp: 50,
      price: 50,
      stock: 2,
    );
    await pumpShop(tester, FakeShopRepository(books: const [scarce]));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Add to cart'));
      await tester.pump(const Duration(seconds: 5));
    }

    expect(cart.count, 2, reason: 'a third copy does not exist');
    expect(
      find.text('Only 2 of Last Two in stock — all are in your cart.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
  });
}

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/pages/publishings_page.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_card.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Product _product({int id = 3244, String name = 'Baitalik', int stock = 12}) =>
    Product(
      id: id,
      name: name,
      author: 'Rabindranath Tagore',
      code: 'BK-$id',
      price: 250,
      stock: stock,
      isActive: true,
    );

class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({List<Product>? items, this.failure})
    : items = items ?? [_product()];

  List<Product> items;
  ApiFailure? failure;

  /// Records what the quantity endpoint was asked to store.
  final List<({int productId, int quantity})> writes = [];
  final List<
    ({int page, String? search, CatalogFilters filters, ProductSort sort})
  >
  reads = [];

  /// The draft each `/filters` request was made for.
  final List<CatalogFilters> facetReads = [];

  /// Set to make the filter-options call fail.
  bool facetsFail = false;

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    int limit = 10,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ProductSort sort = ProductSort.initial,
  }) async {
    reads.add((page: page, search: search, filters: filters, sort: sort));
    if (failure != null) throw failure!;
    return ProductPage(
      items: items,
      page: page,
      limit: limit,
      total: items.length,
      totalPages: 1,
      hasNext: false,
    );
  }

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async {
    facetReads.add(filters);
    if (facetsFail) throw const ApiFailure('Cannot reach the server.');
    return FilterFacets(
      total: 9 - filters.activeCount(const CatalogFilters()),
      categories: const [
        FacetOption(id: '1001', label: 'Poem', count: 103),
        FacetOption(id: '1016', label: 'Autobiography', count: 8),
      ],
      inStock: 7,
      active: 8,
      inactive: 1,
    );
  }

  @override
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    writes.add((productId: productId, quantity: quantity));
    if (failure != null) throw failure!;
    final updated = items
        .firstWhere((p) => p.id == productId)
        .copyWith(stock: quantity);
    items = [for (final p in items) p.id == productId ? updated : p];
    return updated;
  }
}

Future<void> pumpPage(
  WidgetTester tester,
  FakeProductsRepository repository,
) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<ProductsRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: PublishingsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the products returned by /v1/products', (tester) async {
    final repository = FakeProductsRepository(
      items: [
        _product(),
        _product(id: 99, name: 'Gitanjali', stock: 0),
      ],
    );
    await pumpPage(tester, repository);

    expect(find.byType(ProductCard), findsNWidgets(2));
    // Twice: the card title, and the generated cover (no image in tests).
    expect(find.text('Baitalik'), findsNWidgets(2));
    expect(find.text('12 in stock'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(repository.reads.single.page, 1);
  });

  testWidgets('the eye icon opens the product details', (tester) async {
    await pumpPage(
      tester,
      FakeProductsRepository(
        items: [
          const Product(
            id: 3244,
            name: 'Baitalik',
            author: 'Rabindranath Tagore',
            code: 'BK-3244',
            price: 250,
            stock: 12,
            isActive: true,
            isbn: '9788126',
            language: 'Bengali',
            pageCount: 220,
            offeredPrice: 200,
            description: 'A collection of essays.',
          ),
        ],
      ),
    );

    await tester.tap(find.byTooltip('View details'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsDialog), findsOneWidget);
    expect(find.text('9788126'), findsOneWidget);
    expect(find.text('Bengali'), findsOneWidget);
    expect(find.text('220'), findsOneWidget);
    expect(find.text('₹200.00'), findsOneWidget); // offered price
    expect(find.text('A collection of essays.'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsDialog), findsNothing);
  });

  testWidgets('the edit button opens the form with the current quantity', (
    tester,
  ) async {
    await pumpPage(tester, FakeProductsRepository());

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();

    expect(find.text('Update quantity'), findsOneWidget);
    expect(find.text('CURRENT QUANTITY'), findsOneWidget);
    expect(find.text('12'), findsOneWidget); // the old quantity, read-only
    expect(find.text('QUANTITY TO ADD'), findsOneWidget);
  });

  testWidgets('adding to stock previews and saves the combined total', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '25');
    await tester.pumpAndSettle();

    // 12 on hand + 25 added = 37, shown before saving.
    expect(find.text('37'), findsOneWidget);

    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(repository.writes.single.productId, 3244);
    expect(repository.writes.single.quantity, 37);
    // The row updates in place.
    expect(find.text('37 in stock'), findsOneWidget);
    expect(find.text('Baitalik now has 37 in stock.'), findsOneWidget);
  });

  testWidgets('a negative addition is allowed while the total stays valid', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(repository.writes.single.quantity, 7);
  });

  testWidgets('a total below zero is refused before any request', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-50');
    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(find.text('That would leave stock below zero'), findsOneWidget);
    expect(repository.writes, isEmpty);
  });

  testWidgets('an empty box is refused', (tester) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a quantity to add'), findsOneWidget);
    expect(repository.writes, isEmpty);
  });

  testWidgets('a failed save shows the message and keeps the form open', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();

    repository.failure = const ApiFailure(
      'The product catalogue is temporarily unavailable.',
      errorCode: 'CATALOGUE_UNAVAILABLE',
      statusCode: 503,
    );
    await tester.enterText(find.byType(TextFormField), '5');
    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(
      find.text('The product catalogue is temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Update quantity'), findsOneWidget); // still open
  });

  testWidgets('a failed load offers a retry', (tester) async {
    final repository = FakeProductsRepository(
      failure: const ApiFailure('Cannot reach the server.'),
    );
    await pumpPage(tester, repository);

    expect(find.text('Cannot reach the server.'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('TRY AGAIN'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCard), findsOneWidget);
  });

  testWidgets('the form fits above the keyboard on a short screen', (
    tester,
  ) async {
    // A small phone — 360x640, smaller than the device this was first seen on.
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<ProductsRepository>.value(
        value: FakeProductsRepository(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PublishingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();
    expect(find.text('Update quantity'), findsOneWidget);

    // The keyboard comes up: half the screen disappears under it.
    tester.view.viewInsets = const FakeViewPadding(bottom: 320 * 3);
    await tester.pumpAndSettle();

    // No RenderFlex overflow, and the form still works.
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField), '25');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('37'), findsOneWidget); // the preview still updates
  });

  testWidgets('the filter overlay is live, and applying refetches', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    Finder inPanel(String text) => find.descendant(
      of: find.byType(FilterPanelFrame),
      matching: find.text(text),
    );

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    // The options and counts are the publisher's own, from /products/filters.
    expect(inPanel('Poem · 103'), findsOneWidget);
    expect(inPanel('Autobiography · 8'), findsOneWidget);
    expect(inPanel('Active · 8'), findsOneWidget);

    await tester.tap(inPanel('Inactive · 1'));
    await tester.tap(find.byType(Switch));
    await tester.tap(inPanel('Poem · 103'));
    await tester.pumpAndSettle();

    // Each change asked the server what the selection leaves.
    final asked = repository.facetReads.last;
    expect(asked.isActive, isFalse);
    expect(asked.inStockOnly, isTrue);
    expect(asked.categories.single.id, '1001');

    await tester.tap(inPanel('SHOW 6 BOOKS'));
    await tester.pumpAndSettle();

    final filters = repository.reads.last.filters;
    expect(filters.isActive, isFalse);
    expect(filters.inStockOnly, isTrue);
    expect(filters.categories.single.id, '1001');
    expect(repository.reads.last.page, 1);
    expect(find.text('3'), findsOneWidget); // the filter badge
  });

  testWidgets('the sort overlay refetches, and Clear resets it', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: low to high'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.sort, ProductSort.priceLow);

    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CLEAR'));
    await tester.pumpAndSettle();
    expect(repository.reads.last.sort, ProductSort.initial);
  });

  testWidgets('a failed options load says so, and the list is unaffected', (
    tester,
  ) async {
    final repository = FakeProductsRepository()..facetsFail = true;
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();

    expect(find.text("Filter options couldn't be loaded."), findsOneWidget);
    expect(find.byType(ProductCard), findsOneWidget);
  });
}

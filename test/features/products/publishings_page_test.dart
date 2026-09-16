import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/pages/publishings_page.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_card.dart';
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
  final List<({int page, String? search, ProductFilter filter})> reads = [];

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    int limit = 10,
    String? search,
    ProductFilter filter = ProductFilter.all,
    ProductSort sort = ProductSort.newest,
  }) async {
    reads.add((page: page, search: search, filter: filter));
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
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    writes.add((productId: productId, quantity: quantity));
    if (failure != null) throw failure!;
    final updated = items
        .firstWhere((p) => p.id == productId)
        .copyWith(stock: quantity);
    items = [
      for (final p in items) p.id == productId ? updated : p,
    ];
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
      items: [_product(), _product(id: 99, name: 'Gitanjali', stock: 0)],
    );
    await pumpPage(tester, repository);

    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('Baitalik'), findsOneWidget);
    expect(find.text('12 in stock'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(repository.reads.single.page, 1);
  });

  testWidgets('the edit button opens the form with the current quantity',
      (tester) async {
    await pumpPage(tester, FakeProductsRepository());

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();

    expect(find.text('Update quantity'), findsOneWidget);
    expect(find.text('CURRENT QUANTITY'), findsOneWidget);
    expect(find.text('12'), findsOneWidget); // the old quantity, read-only
    expect(find.text('QUANTITY TO ADD'), findsOneWidget);
  });

  testWidgets('adding to stock previews and saves the combined total',
      (tester) async {
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

  testWidgets('a negative addition is allowed while the total stays valid',
      (tester) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Edit quantity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '-5');
    await tester.tap(find.text('SAVE QUANTITY'));
    await tester.pumpAndSettle();

    expect(repository.writes.single.quantity, 7);
  });

  testWidgets('a total below zero is refused before any request',
      (tester) async {
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

  testWidgets('a failed save shows the message and keeps the form open',
      (tester) async {
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

  testWidgets('filtering refetches from the server', (tester) async {
    final repository = FakeProductsRepository();
    await pumpPage(tester, repository);

    await tester.tap(find.text('Inactive'));
    await tester.pumpAndSettle();

    expect(repository.reads.last.filter, ProductFilter.inactive);
    expect(repository.reads.last.page, 1);
  });
}

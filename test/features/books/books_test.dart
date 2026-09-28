import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/pages/books_hub_page.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/pages/publishings_page.dart';
import 'package:bookslane_app/features/products/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('hub', () {
    testWidgets('offers both shelves and reports which was picked', (
      tester,
    ) async {
      BookSource? picked;
      await pump(
        tester,
        BooksHubPage(onSourceSelected: (source) => picked = source),
      );

      expect(find.text('My Store'), findsOneWidget);
      expect(find.text('My Publishings'), findsOneWidget);

      await tester.tap(find.text('My Store'));
      expect(picked, BookSource.store);

      await tester.tap(find.text('My Publishings'));
      expect(picked, BookSource.publishings);
    });
  });

  // My Publishings is the thinkerslane catalogue from GET /v1/products.
  // BookListPage hands that shelf to PublishingsPage, which reads through
  // ProductsRepository — publishings_page_test.dart covers the page itself.
  group('publishings shelf', () {
    Future<_FakeProducts> pumpShelf(
      WidgetTester tester, {
      VoidCallback? onBack,
    }) async {
      final repository = _FakeProducts();
      await pump(
        tester,
        Provider<ProductsRepository>.value(
          value: repository,
          child: BookListPage(source: BookSource.publishings, onBack: onBack),
        ),
      );
      return repository;
    }

    testWidgets('loads the products from the API', (tester) async {
      final repository = await pumpShelf(tester);

      expect(find.byType(PublishingsPage), findsOneWidget);
      expect(find.text('My Publishings'), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);
      // Twice: the card title, and the generated cover (no image in tests).
      expect(find.text('Baitalik'), findsNWidgets(2));
      expect(repository.pagesRead, [1]);
    });

    testWidgets('back returns to the hub', (tester) async {
      var wentBack = false;
      await pumpShelf(tester, onBack: () => wentBack = true);

      await tester.tap(find.byTooltip('Back'));
      expect(wentBack, isTrue);
    });
  });
}

class _FakeProducts implements ProductsRepository {
  final List<int> pagesRead = [];

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    int limit = 10,
    String? search,
    ProductFilters filters = ProductFilters.initial,
    ProductSort sort = ProductSort.initial,
  }) async {
    pagesRead.add(page);
    return ProductPage(
      items: const [
        Product(
          id: 3244,
          name: 'Baitalik',
          author: 'Rabindranath Tagore',
          code: 'BK-3244',
          price: 250,
          stock: 12,
          isActive: true,
        ),
      ],
      page: page,
      limit: limit,
      total: 1,
      totalPages: 1,
      hasNext: false,
    );
  }

  @override
  Future<List<ProductCategory>> fetchCategories() async => const [];

  @override
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  }) => throw UnimplementedError();
}

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/auth/domain/entities/user.dart';
import 'package:bookslane_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:bookslane_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/pages/books_hub_page.dart';
import 'package:bookslane_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:bookslane_app/features/dashboard/presentation/widgets/home_tab.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';
import 'package:bookslane_app/features/products/presentation/pages/publishings_page.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/domain/repositories/shop_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _StubRepo implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async =>
      const User(id: '1', email: 'anna@bookslane.com', name: 'Anna');
  @override
  Future<void> logout() async {}
  @override
  Future<User?> restoreSession() async =>
      const User(id: '1', email: 'anna@bookslane.com', name: 'Anna');
}

/// My Publishings talks to /v1/products, so the shell needs a repository.
/// One in-stock book, so the Shop tab has something to add to the cart.
class _StubShop implements ShopRepository {
  @override
  Future<ShopBookPage> fetchBooks({
    required int page,
    int limit = 20,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ShopSort sort = ShopSort.initial,
  }) async => const ShopBookPage(
    items: [
      ShopBook(
        id: 'publishing-1',
        source: ShopSource.publishing,
        refId: 1,
        title: 'Baitalik',
        author: 'Tagore',
        sku: 'TL-1',
        mrp: 100,
        price: 90,
        stock: 5,
      ),
    ],
    page: 1,
    limit: 20,
    total: 1,
    totalPages: 1,
    hasNext: false,
  );

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async => const FilterFacets(total: 1);
}

class _StubProducts implements ProductsRepository {
  @override
  Future<ProductPage> fetchProducts({
    required int page,
    int limit = 10,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ProductSort sort = ProductSort.initial,
  }) async => const ProductPage(
    items: [
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
    page: 1,
    limit: 10,
    total: 1,
    totalPages: 1,
    hasNext: false,
  );

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async => const FilterFacets(total: 0);

  @override
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  }) async => throw UnimplementedError();
}

/// My Store talks to /v1/books, so the shell needs this one too.
class _StubBooks implements BooksRepository {
  @override
  Future<List<BookCategory>> fetchCategories() async => const [];

  @override
  Future<FilterFacets> fetchFilters(
    CatalogFilters filters, {
    String? search,
  }) async => const FilterFacets(total: 0);

  @override
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    BookSort sort = BookSort.initial,
  }) async => const BookPage(
    items: [],
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 0,
    hasNext: false,
  );

  @override
  Future<BookDetail> getBook(String id) async => throw UnimplementedError();

  @override
  Future<Book> createBook(BookDraft draft) async => throw UnimplementedError();

  @override
  Future<Book> updateBook(String id, BookDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<Book> setActive({required String id, required bool isActive}) async =>
      throw UnimplementedError();
}

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(_StubRepo())..bootstrap(),
          ),
          Provider<ProductsRepository>(create: (_) => _StubProducts()),
          Provider<BooksRepository>(create: (_) => _StubBooks()),
          Provider<ShopRepository>(create: (_) => _StubShop()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const DashboardPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder navItem(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  testWidgets('the second tab is Books, not Products', (tester) async {
    await pumpShell(tester);

    expect(navItem('Books'), findsOneWidget);
    expect(navItem('Products'), findsNothing);
  });

  testWidgets('Books opens the hub, a shelf opens the list, back returns', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byType(HomeTab), findsOneWidget);

    await tester.tap(navItem('Books'));
    await tester.pumpAndSettle();
    expect(find.byType(BooksHubPage), findsOneWidget);
    expect(find.byType(HomeTab), findsNothing);

    await tester.tap(find.text('My Publishings'));
    await tester.pumpAndSettle();
    // Live data from /v1/products, not the sample shelf.
    expect(find.byType(PublishingsPage), findsOneWidget);
    // Twice: the card title, and the generated cover (no image in tests).
    expect(find.text('Baitalik'), findsNWidgets(2));
    // The bottom bar stays put — the list is a tab body, not a pushed route.
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(BooksHubPage), findsOneWidget);
  });

  testWidgets('tapping Books while on a shelf goes back up to the hub', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(navItem('Books'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Store'));
    await tester.pumpAndSettle();
    expect(find.byType(BookListPage), findsOneWidget);

    await tester.tap(navItem('Books'));
    await tester.pumpAndSettle();

    expect(find.byType(BooksHubPage), findsOneWidget);
  });

  testWidgets('an inner page swaps the branded bar for its own', (
    tester,
  ) async {
    await pumpShell(tester);
    // The tab root shows the branded bar.
    expect(find.text('Bookslane'), findsOneWidget);

    await tester.tap(navItem('Books'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Store'));
    await tester.pumpAndSettle();

    // Inner page: no logo row, just the title and a way back.
    expect(find.text('Bookslane'), findsNothing);
    expect(find.text('My Store'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    // The bottom bar stays, so tabs are still reachable.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('the unbuilt tabs say so instead of showing the last one', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(navItem('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('This screen is not built yet.'), findsOneWidget);
    expect(find.byType(HomeTab), findsNothing);
  });

  group('the app bar\'s right-hand button', () {
    testWidgets('is sign-out on every tab but the Shop', (tester) async {
      await pumpShell(tester);

      for (final tab in ['Home', 'Books', 'Orders', 'Profile']) {
        await tester.tap(navItem(tab));
        await tester.pumpAndSettle();
        expect(find.byTooltip('Log out'), findsOneWidget, reason: tab);
        expect(find.byTooltip('Cart'), findsNothing, reason: tab);
      }
    });

    testWidgets('is a cart on the Shop, in place of sign-out', (tester) async {
      await pumpShell(tester);

      await tester.tap(navItem('Shop'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Cart'), findsOneWidget);
      expect(find.byTooltip('Log out'), findsNothing);
      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      // The bell is still there beside it.
      expect(find.byTooltip('Notifications'), findsOneWidget);
    });

    testWidgets('the cart badge counts what was added, in red like the bell', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(navItem('Shop'));
      await tester.pumpAndSettle();

      Finder badge(String tooltip, String text) => find.descendant(
        of: find.byTooltip(tooltip),
        matching: find.text(text),
      );

      // Empty cart: no badge at all.
      expect(
        find.descendant(
          of: find.byTooltip('Cart'),
          matching: find.byType(Text),
        ),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Add to cart'));
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byTooltip('Add to cart'));
      await tester.pump(const Duration(seconds: 5));

      expect(badge('Cart', '2'), findsOneWidget);

      // Same red circle the bell uses for its count.
      final dot = tester.widget<Container>(
        find
            .ancestor(of: badge('Cart', '2'), matching: find.byType(Container))
            .first,
      );
      expect((dot.decoration! as BoxDecoration).color, AppColors.ctaBackground);
    });

    testWidgets('the cart survives switching tabs', (tester) async {
      await pumpShell(tester);
      await tester.tap(navItem('Shop'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add to cart'));
      await tester.pump(const Duration(seconds: 5));

      await tester.tap(navItem('Home'));
      await tester.pumpAndSettle();
      await tester.tap(navItem('Shop'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byTooltip('Cart'), matching: find.text('1')),
        findsOneWidget,
      );
    });

    testWidgets('tapping the cart says what is in it', (tester) async {
      await pumpShell(tester);
      await tester.tap(navItem('Shop'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cart'));
      await tester.pump();
      expect(find.text('Your cart is empty.'), findsOneWidget);
      // Toasts queue behind one another; let each one run its course.
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add to cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cart'));
      // The "added" toast is still up; the new one replaces it once that has
      // slid away.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('1 item in your cart — checkout is coming soon.'),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });
}

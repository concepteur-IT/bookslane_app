import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/sample_books.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/pages/books_hub_page.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_card.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('hub', () {
    testWidgets('offers both shelves and reports which was picked',
        (tester) async {
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

  // My Store is now real data (GET /v1/books) — see BooksProvider and
  // book_list_page.dart. My Publishings is still the shelf that runs over
  // SampleBooks in memory, so this whole group exercises that machinery
  // through BookSource.publishings instead of a live network call.
  group('list', () {
    testWidgets('shows the first page of the chosen shelf', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      expect(find.text('My Publishings'), findsOneWidget);
      expect(find.byType(BookCard), findsNWidgets(6)); // page size
      expect(find.text('6 of ${SampleBooks.publishings.length}'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('the two shelves show different books', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      expect(find.text('My Publishings'), findsOneWidget);
      expect(find.text('The Malmö Letters'), findsOneWidget);
      expect(find.text('Travel Journal'), findsNothing);
    });

    testWidgets('paging forward shows the rest', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));
      expect(find.text('The Malmö Letters'), findsOneWidget);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('The Malmö Letters'), findsNothing);
      expect(find.text('First Words'), findsOneWidget);
    });

    testWidgets('filtering narrows the list and resets to page one',
        (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);

      // "Inactive" is also a status pill on the cards — tap the chip.
      await tester.tap(
        find.descendant(
          of: find.byType(BookFilterBar),
          matching: find.text('Inactive'),
        ),
      );
      await tester.pumpAndSettle();

      final inactive = SampleBooks.publishings.where((b) => !b.isActive).length;
      expect(find.byType(BookCard), findsNWidgets(inactive));
      expect(find.text('$inactive of $inactive'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget, reason: 'must reset the page');
    });

    testWidgets('search matches title and subtitle', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      await tester.enterText(find.byType(AppSearchField), 'seafood');
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsOneWidget);
      expect(find.text('Coastal Recipes'), findsOneWidget);
    });

    testWidgets('a search with no matches shows the empty state',
        (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      await tester.enterText(find.byType(AppSearchField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.byType(BookCard), findsNothing);
      expect(find.text('No books match that.'), findsOneWidget);
    });

    testWidgets('sorting by name reorders the page', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      await tester.tap(
        find.descendant(
          of: find.byType(BookSortBar),
          matching: find.text('Name'),
        ),
      );
      await tester.pumpAndSettle();

      final titles = tester
          .widgetList<BookCard>(find.byType(BookCard))
          .map((card) => card.book.title)
          .toList();
      final sorted = [...titles]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(titles, sorted);
      expect(titles.first, 'Building Bookslane');
    });

    testWidgets('the dot toggles active state', (tester) async {
      await pump(tester, const BookListPage(source: BookSource.publishings));

      // Winter Light is inactive to begin with, and the only inactive title
      // on the first page.
      expect(find.byTooltip('Activate'), findsWidgets);
      await tester.tap(find.byTooltip('Activate').first);
      await tester.pumpAndSettle();

      expect(find.text('Winter Light is now active.'), findsOneWidget);
    });

    testWidgets('back returns to the hub', (tester) async {
      var wentBack = false;
      await pump(
        tester,
        BookListPage(
          source: BookSource.publishings,
          onBack: () => wentBack = true,
        ),
      );

      await tester.tap(find.byTooltip('Back'));
      expect(wentBack, isTrue);
    });
  });
}

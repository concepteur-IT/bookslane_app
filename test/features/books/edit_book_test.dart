import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_detail.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';

/// Stands in for `/v1/books/:id` (GET and PATCH) — one book, held as full
/// detail so [getBook] has something real to prefill the Edit Book form
/// from, and [updateBook] actually applies what was submitted.
class _FakeBooksRepository implements BooksRepository {
  _FakeBooksRepository(this._detail);

  BookDetail _detail;

  Book get _asListRow => Book(
    id: _detail.id,
    title: _detail.title,
    subtitle: _detail.subtitle.isNotEmpty ? _detail.subtitle : _detail.author,
    price: (_detail.price * 100).round(),
    stock: _detail.quantity,
    isActive: _detail.status == BookStatus.active,
    addedOn: DateTime(2026, 1, 1),
    imageUrl: _detail.imageUrl,
  );

  @override
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    BookFilters filters = BookFilters.initial,
    BookSort sort = BookSort.initial,
  }) async => BookPage(
    items: [_asListRow],
    page: 1,
    limit: limit,
    total: 1,
    totalPages: 1,
    hasNext: false,
  );

  @override
  Future<BookDetail> getBook(String id) async => _detail;

  @override
  Future<Book> createBook(BookDraft draft) async => throw UnimplementedError();

  @override
  Future<Book> updateBook(String id, BookDraft draft) async {
    _detail = BookDetail(
      id: _detail.id,
      title: draft.title,
      subtitle: draft.subtitle,
      sku: draft.sku,
      author: draft.author,
      description: draft.description,
      language: draft.language,
      category: draft.category,
      binding: draft.binding,
      price: draft.price,
      discount: draft.discount,
      discountType: draft.discountType,
      effectivePrice: draft.effectivePrice,
      quantity: draft.quantity,
      status: draft.status,
      // Untouched: none of these tests pick a new cover.
      imageUrl: _detail.imageUrl,
    );
    return _asListRow;
  }

  @override
  Future<Book> setActive({required String id, required bool isActive}) async =>
      throw UnimplementedError();
}

void main() {
  late _FakeBooksRepository repository;

  setUp(() {
    // Deliberately distinct from every hardcoded hint in add_book.dart (e.g.
    // the Title field's hint literally is 'The Guide') — sharing a value with
    // a hint makes `find.text`/`find.widgetWithText` ambiguous, since an
    // InputDecorator can keep the hint's Text mounted (faded) even once the
    // field has real content.
    repository = _FakeBooksRepository(
      const BookDetail(
        id: '1',
        title: 'Malgudi Nights',
        subtitle: 'A short story collection',
        sku: 'BL-EDIT-01',
        author: 'Narayan K. Ramaswami',
        description: 'An edited description of the book.',
        language: BookLanguage.english,
        category: BookCategory.fiction,
        binding: BookBinding.paperback,
        price: 199.5,
        discount: 0,
        discountType: DiscountType.flat,
        effectivePrice: 199.5,
        quantity: 8,
        status: BookStatus.active,
      ),
    );
  });

  Future<void> pumpList(WidgetTester tester) async {
    // The Edit Book sheet is as tall as Add Book — taller than the default
    // 800x600 test surface — so a big single-jump `ensureVisible` (unlike
    // add_book_connection_test.dart's field-by-field descent) can land
    // outside the viewport entirely. See add_book_form_test.dart's pumpForm
    // for the same fix.
    await tester.binding.setSurfaceSize(const Size(500, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
  }

  /// Same centring trick as add_book_connection_test.dart — plain
  /// ensureVisible can leave a target flush against the sheet's clipped
  /// edge, where a tap lands on the scrim instead and dismisses the form.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the eye icon shows the book\'s full details', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.byTooltip('View details'));
    await tester.pumpAndSettle();

    // The card behind the dialog stays mounted, so its text counts too — and
    // the title three times: card, the card's generated cover, the dialog.
    expect(find.text('Malgudi Nights'), findsNWidgets(3));
    expect(find.text('A short story collection'), findsNWidgets(2));
    expect(find.text('An edited description of the book.'), findsOneWidget);
    expect(find.text('BL-EDIT-01'), findsOneWidget);
    expect(find.text('Narayan K. Ramaswami'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Fiction'), findsOneWidget);
    expect(find.text('Paperback'), findsOneWidget);
    // Card price + dialog's Price row + dialog's Selling price row (equal,
    // since this book has no discount).
    expect(find.text('₹199.50'), findsNWidgets(3));
    // Card's stock pill + dialog's Quantity row.
    expect(find.text('8 in stock'), findsNWidgets(2));
    expect(find.text('Active'), findsWidgets);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('tapping edit opens the sheet prefilled with the book\'s data', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit book'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Malgudi Nights'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'A short story collection'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'BL-EDIT-01'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Narayan K. Ramaswami'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'An edited description of the book.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, '199.50'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '8'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Fiction'), findsOneWidget);
    expect(find.text('Paperback'), findsOneWidget);
    expect(find.text('SAVE CHANGES'), findsOneWidget);

    // Unlike Add Book, no cover is required to save an edit.
    await reveal(tester, find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pumpAndSettle();
    expect(find.text('Please add a cover image'), findsNothing);
  });

  testWidgets('saving without picking a new cover updates the card', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();

    final titleField = find.widgetWithText(TextFormField, 'Malgudi Nights');
    await reveal(tester, titleField);
    await tester.enterText(titleField, 'Malgudi Nights, Revised');
    await tester.pump();

    await reveal(tester, find.text('SAVE CHANGES'));
    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pumpAndSettle();

    expect(find.text('SAVE CHANGES'), findsNothing);
    // Twice: the card title, and the generated cover (no image in tests).
    expect(find.text('Malgudi Nights, Revised'), findsNWidgets(2));
    expect(find.text('Malgudi Nights, Revised updated.'), findsOneWidget);
  });

  testWidgets('dismissing the edit sheet leaves the book untouched', (
    tester,
  ) async {
    await pumpList(tester);
    // Twice: the card title, and the generated cover (no image in tests).
    expect(find.text('Malgudi Nights'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('SAVE CHANGES'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('SAVE CHANGES'), findsNothing);
    // Twice: the card title, and the generated cover (no image in tests).
    expect(find.text('Malgudi Nights'), findsNWidgets(2));
  });
}

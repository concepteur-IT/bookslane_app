import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/books/domain/entities/book.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/domain/repositories/books_repository.dart';
import 'package:bookslane_app/features/books/presentation/pages/book_list_page.dart';
import 'package:bookslane_app/features/books/presentation/widgets/book_card.dart';

/// Stands in for `/v1/books` — an in-memory list, shaped the way
/// [BookModel.toEntity] would produce it, without a server. [BooksProvider]
/// calls [fetchBooks] itself (on load, and again after every [createBook]),
/// so this has to actually hold state rather than just answer `createBook`.
class _FakeBooksRepository implements BooksRepository {
  final List<Book> _books = [];
  int _nextId = 1;

  @override
  Future<BookPage> fetchBooks({
    required int page,
    int limit = 10,
    String? search,
    BookFilter filter = BookFilter.all,
    BookSort sort = BookSort.newest,
  }) async {
    return BookPage(
      items: List.of(_books),
      page: 1,
      limit: limit,
      total: _books.length,
      totalPages: 1,
      hasNext: false,
    );
  }

  @override
  Future<Book> createBook(BookDraft draft) async {
    final book = Book(
      id: 'fake-${_nextId++}',
      title: draft.title,
      // Same fallback BookModel.toEntity applies for a real response.
      subtitle: draft.subtitle.isNotEmpty ? draft.subtitle : draft.author,
      price: (draft.price * 100).round(),
      stock: draft.quantity,
      isActive: draft.status == BookStatus.active,
      addedOn: DateTime.now(),
    );
    _books.insert(0, book);
    return book;
  }

  @override
  Future<Book> setActive({required String id, required bool isActive}) async {
    final index = _books.indexWhere((book) => book.id == id);
    final updated = _books[index].copyWith(isActive: isActive);
    _books[index] = updated;
    return updated;
  }
}

/// A 1x1 PNG — enough for `Image.memory` to decode a real thumbnail.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

/// Stands in for the platform picker, which has no camera or gallery in a
/// widget test. The base constructor passes the platform token, so a plain
/// subclass is accepted as the instance.
class _FakeImagePicker extends ImagePickerPlatform {
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
    // `path` matters: XFile derives `name` from it, and ignores the `name`
    // argument outside the web. `readAsBytes` still serves the bytes above,
    // so nothing touches the filesystem.
  }) async => XFile.fromData(
    _png,
    path: 'cover.png',
    name: 'cover.png',
    mimeType: 'image/png',
  );
}

void main() {
  setUp(() => ImagePickerPlatform.instance = _FakeImagePicker());

  Future<void> pumpList(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Provider<BooksRepository>.value(
          value: _FakeBooksRepository(),
          child: const BookListPage(source: BookSource.store),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls [finder] to the middle of the sheet before it is touched.
  ///
  /// `tester.ensureVisible` stops as soon as the widget is technically on
  /// screen, which leaves it flush against the clipped edge of the sheet —
  /// a tap there lands on the scrim and dismisses the form. Centring it
  /// removes that whole class of flake.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(
      tester.element(finder),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String hint, String value) async {
    final field = find.widgetWithText(TextFormField, hint);
    await reveal(tester, field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> selectDropdown<T>(WidgetTester tester, String option) async {
    final dropdown = find.byType(DropdownButtonFormField<T>);
    await reveal(tester, dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the Add button opens the form, titled for this shelf', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add to ${BookSource.store.label}'), findsOneWidget);
    expect(find.text('ADD BOOK'), findsOneWidget);
  });

  testWidgets('dismissing the sheet leaves the list alone', (tester) async {
    await pumpList(tester);
    final before = find.byType(BookCard).evaluate().length;

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    // Back out without submitting.
    Navigator.of(tester.element(find.text('ADD BOOK'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('ADD BOOK'), findsNothing);
    expect(find.byType(BookCard).evaluate().length, before);
  });

  testWidgets('a submitted book lands at the top of the list', (tester) async {
    await pumpList(tester);

    expect(find.text('Wuthering Heights'), findsNothing);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Cover image: tap the field, then pick Gallery from its sheet.
    await reveal(tester, find.text('Choose a cover image'));
    await tester.tap(find.text('Choose a cover image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(find.text('cover.png'), findsOneWidget);

    await enter(tester, 'The Guide', 'Wuthering Heights');
    await enter(tester, 'R. K. Narayan', 'Emily Bronte');
    await enter(tester, 'BL-0001', 'BL-9001');
    await enter(tester, '249.00', '450');
    await enter(tester, '10', '7');

    await selectDropdown<BookLanguage>(tester, 'English');
    await selectDropdown<BookCategory>(tester, 'Fiction');
    await selectDropdown<BookBinding>(tester, 'Hardcover');

    await reveal(tester, find.text('ADD BOOK'));
    await tester.tap(find.text('ADD BOOK'));
    await tester.pumpAndSettle();

    // The sheet closed and the book is on the list, with the author standing
    // in for the empty subtitle and the price converted to minor units.
    expect(find.text('ADD BOOK'), findsNothing);
    expect(find.text('Wuthering Heights'), findsOneWidget);
    expect(find.text('Emily Bronte'), findsOneWidget);
    expect(find.textContaining('450'), findsWidgets);
    expect(
      find.text('Wuthering Heights added to ${BookSource.store.label}.'),
      findsOneWidget,
    );
  });
}

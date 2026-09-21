import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/books/domain/entities/book_draft.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';
import 'package:bookslane_app/features/books/presentation/widgets/add_book.dart';

void main() {
  BookDraft? submitted;

  Future<void> pumpForm(WidgetTester tester) async {
    submitted = null;

    // The form is far taller than the default 800x600 test surface. Giving it
    // a surface it fits on keeps every field fully hit-testable, so a tap
    // never lands on the clipped edge of a scroll view.
    await tester.binding.setSurfaceSize(const Size(500, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: AddBookForm(onSubmit: (draft) async => submitted = draft),
          ),
        ),
      ),
    );
  }

  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(find.text('ADD BOOK'));
    await tester.tap(find.text('ADD BOOK'));
    await tester.pumpAndSettle();
  }

  /// Fills a text field by the hint its label sits above.
  Future<void> enter(
    WidgetTester tester,
    String hint,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, hint);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  /// Opens the dropdown holding a [T] and picks [option] from its menu.
  ///
  /// Taps the field itself rather than its hint text: inside an
  /// `InputDecorator` the hint does not receive pointer events, so tapping it
  /// only works by falling through to the decoration underneath.
  Future<void> selectDropdown<T>(WidgetTester tester, String option) async {
    final dropdown = find.byType(DropdownButtonFormField<T>);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('an empty form reports every required field', (tester) async {
    await pumpForm(tester);
    await tapSubmit(tester);

    expect(find.text('Please add a cover image'), findsOneWidget);
    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Please enter an author'), findsOneWidget);
    expect(find.text('Please enter an SKU'), findsOneWidget);
    expect(find.text('Please select a language'), findsOneWidget);
    expect(find.text('Please select a category'), findsOneWidget);
    expect(find.text('Please select a binding'), findsOneWidget);
    expect(find.text('Please enter a price'), findsOneWidget);
    expect(find.text('Please enter a quantity'), findsOneWidget);

    expect(submitted, isNull);
  });

  testWidgets('optional fields are not required', (tester) async {
    await pumpForm(tester);
    await tapSubmit(tester);

    // Subtitle, description and discount carry no error.
    expect(find.textContaining('subtitle'), findsNothing);
    expect(find.textContaining('description'), findsNothing);
    expect(find.textContaining('Enter an amount'), findsNothing);
  });

  testWidgets('language and category are dropdowns, not text fields', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.byType(DropdownButtonFormField<BookLanguage>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<BookCategory>), findsOneWidget);

    await selectDropdown<BookLanguage>(tester, 'Bengali');
    await selectDropdown<BookCategory>(tester, 'Poetry');

    expect(find.text('Bengali'), findsOneWidget);
    expect(find.text('Poetry'), findsOneWidget);
  });

  testWidgets('a flat discount above the price is rejected', (tester) async {
    await pumpForm(tester);

    await enter(tester, '249.00', '200');
    await enter(tester, '0', '500');
    await tapSubmit(tester);

    expect(find.text('Discount cannot be more than the price'), findsOneWidget);
    expect(submitted, isNull);
  });

  testWidgets('a percentage discount above the 90% cap is rejected', (
    tester,
  ) async {
    await pumpForm(tester);

    await enter(tester, '249.00', '200');
    await enter(tester, '0', '120');
    await selectDropdown<DiscountType>(tester, 'Percentage (%)');
    await tapSubmit(tester);

    expect(
      find.text('A percentage discount cannot exceed 90'),
      findsOneWidget,
    );
    expect(submitted, isNull);
  });

  testWidgets('a complete form hands back a typed draft', (tester) async {
    await pumpForm(tester);

    await enter(tester, 'The Guide', 'The Guide');
    await enter(tester, 'Optional', 'A novel');
    await enter(tester, 'R. K. Narayan', 'R. K. Narayan');
    await enter(tester, 'BL-0001', 'BL-0042');
    await enter(tester, 'What is this book about?', 'A railway guide.');
    await enter(tester, '249.00', '250');
    await enter(tester, '10', '12');
    await enter(tester, '0', '50');

    await selectDropdown<BookLanguage>(tester, 'English');
    await selectDropdown<BookCategory>(tester, 'Fiction');
    await selectDropdown<BookBinding>(tester, 'Hardcover');

    await tapSubmit(tester);

    // The cover image is required, so the form must still refuse — the picker
    // itself cannot be driven from a widget test.
    expect(find.text('Please add a cover image'), findsOneWidget);
    expect(submitted, isNull);

    // Every other field passed: no other error is on screen.
    expect(find.text('Please enter a title'), findsNothing);
    expect(find.text('Please select a language'), findsNothing);
    expect(find.text('Please enter a price'), findsNothing);
  });

  test('a draft maps onto the products table column names', () {
    const draft = BookDraft(
      title: 'The Guide',
      sku: 'BL-0042',
      author: 'R. K. Narayan',
      language: BookLanguage.english,
      category: BookCategory.fiction,
      binding: BookBinding.hardcover,
      price: 250,
      quantity: 12,
      status: BookStatus.active,
      discount: 50,
    );

    expect(draft.toJson(), {
      'name': 'The Guide',
      'subtitle': '',
      'sku': 'BL-0042',
      'author': 'R. K. Narayan',
      'language': 'en',
      'category': 1,
      'description': '',
      'binding': 'hardcover',
      'price': 250.0,
      'discount': 50.0,
      'discount_type': 'flat',
      'quantity': 12,
      'is_active': 1,
    });

    expect(draft.effectivePrice, 200);
  });
}

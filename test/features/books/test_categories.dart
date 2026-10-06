import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/features/books/domain/entities/book_form_options.dart';

/// Categories as `GET /v1/categories` returns them — real thinkerslane ids
/// and names, so the tests read like the data they stand in for.
const testPoem = BookCategory(id: 1001, name: 'Poem');
const testNonFiction = BookCategory(id: 1018, name: 'Non-fiction');
const testCategories = [testPoem, testNonFiction];

/// The same two as filter options, as `/filters` returns them.
const testPoemFacet = FacetOption(id: '1001', label: 'Poem');
const testNonFictionFacet = FacetOption(id: '1018', label: 'Non-fiction');

import 'package:flutter/foundation.dart';

import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

/// What happened when a book was added.
enum CartAddResult {
  /// One more of it is in the cart.
  added,

  /// Nothing was added: the cart already holds every unit in stock.
  atStockLimit,

  /// Nothing was added: the book is sold out.
  soldOut,
}

/// One book in the cart and how many of it.
class CartLine {
  const CartLine({required this.book, required this.quantity});

  final ShopBook book;
  final int quantity;
}

/// The Shop cart, in memory.
///
/// There is no checkout or orders flow yet, so nothing is persisted or sent to
/// the server: this holds what has been added so the count on the app bar is
/// real. It lives in the dashboard shell, so it survives switching tabs and is
/// gone on sign-out — a cart belongs to the account that filled it.
class CartProvider extends ChangeNotifier {
  /// Keyed by [ShopBook.id], which is unique across both shelves.
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => List.unmodifiable(_lines.values);

  /// Total units across all books — what the badge shows. Two copies of one
  /// book count as two.
  int get count => _lines.values.fold(0, (sum, line) => sum + line.quantity);

  bool get isEmpty => _lines.isEmpty;

  int quantityOf(ShopBook book) => _lines[book.id]?.quantity ?? 0;

  /// Puts one more of [book] in the cart, never more than it has in stock —
  /// a retailer can't order what the shelf doesn't hold.
  CartAddResult add(ShopBook book) {
    if (book.isSoldOut) return CartAddResult.soldOut;

    final have = quantityOf(book);
    if (have >= book.stock) return CartAddResult.atStockLimit;

    _lines[book.id] = CartLine(book: book, quantity: have + 1);
    notifyListeners();
    return CartAddResult.added;
  }

  void clear() {
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}

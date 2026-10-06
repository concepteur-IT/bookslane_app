import 'package:flutter_test/flutter_test.dart';

import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

ShopBook book({String id = 'publishing-1', int stock = 3}) => ShopBook(
  id: id,
  source: ShopSource.publishing,
  refId: 1,
  title: 'Baitalik',
  author: 'Tagore',
  sku: 'TL-1',
  mrp: 100,
  price: 90,
  stock: stock,
);

void main() {
  late CartProvider cart;
  late int notifications;

  setUp(() {
    cart = CartProvider();
    notifications = 0;
    cart.addListener(() => notifications++);
  });

  test('starts empty', () {
    expect(cart.count, 0);
    expect(cart.isEmpty, isTrue);
    expect(cart.lines, isEmpty);
  });

  test('adding the same book twice is one line of two', () {
    final b = book();

    expect(cart.add(b), CartAddResult.added);
    expect(cart.add(b), CartAddResult.added);

    expect(cart.lines, hasLength(1));
    expect(cart.quantityOf(b), 2);
    expect(cart.count, 2, reason: 'the badge counts units, not titles');
  });

  test('different books are different lines — even with the same number', () {
    // A publishing and a store book can share a number; the ids differ.
    cart.add(book(id: 'publishing-7'));
    cart.add(book(id: 'store-7'));

    expect(cart.lines, hasLength(2));
    expect(cart.count, 2);
  });

  test('never holds more than the shelf has in stock', () {
    final b = book(stock: 2);

    expect(cart.add(b), CartAddResult.added);
    expect(cart.add(b), CartAddResult.added);
    expect(cart.add(b), CartAddResult.atStockLimit);

    expect(cart.count, 2);
  });

  test('a sold-out book cannot be added', () {
    expect(cart.add(book(stock: 0)), CartAddResult.soldOut);

    expect(cart.isEmpty, isTrue);
    expect(notifications, 0, reason: 'nothing changed, so nobody is told');
  });

  test('tells listeners only when the cart really changed', () {
    final b = book(stock: 1);

    cart.add(b); // changed
    cart.add(b); // at the limit — unchanged
    expect(notifications, 1);

    cart.clear(); // changed
    cart.clear(); // already empty
    expect(notifications, 2);
    expect(cart.count, 0);
  });
}

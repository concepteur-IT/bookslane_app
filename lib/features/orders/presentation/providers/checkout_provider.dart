import 'package:flutter/foundation.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:bookslane_app/features/orders/domain/entities/order.dart';
import 'package:bookslane_app/features/orders/domain/repositories/orders_repository.dart';

/// State of one checkout: the flat discount the seller entered and the order
/// being placed. Created when the checkout page opens, so leaving it (to edit
/// the cart) drops the discount — it was checked against that cart's subtotal.
///
/// The server re-checks the discount when the order is placed.
class CheckoutProvider extends ChangeNotifier {
  CheckoutProvider({required this.repository, required this.cart});

  final OrdersRepository repository;
  final CartProvider cart;

  double _discount = 0;
  String? _discountError;
  bool _isPlacing = false;
  PlacedOrder? _lastOrder;

  CustomerDetails? _customer;
  String? _customerId;

  /// What the seller typed on the customer screen, kept so coming back
  /// (Cancel on the QR screen) doesn't mean retyping it.
  CustomerDetails? get customer => _customer;

  /// Saves [details] as a customer — unless exactly these were saved already
  /// in this checkout. Throws [ApiFailure].
  Future<void> saveCustomer(CustomerDetails details) async {
    if (_customerId != null && _customer == details) return;
    _customerId = await repository.saveCustomer(details);
    _customer = details;
  }

  /// The order the server accepted, for the thank-you screen.
  PlacedOrder? get lastOrder => _lastOrder;

  /// Flat amount off, in rupees; 0 when none is applied.
  double get discount => _discount;
  bool get hasDiscount => _discount > 0;

  /// Why the last Apply was refused, phrased for the user.
  String? get discountError => _discountError;
  bool get isPlacing => _isPlacing;

  double get subtotal => cart.total;

  /// Whole paise, so the figure matches what the server stores.
  double get total => (((subtotal - _discount) * 100).round()) / 100;

  /// Validates [raw] as a rupee amount no greater than the subtotal and, if
  /// it is, applies it. Entirely local: nothing is sent until the order is.
  void applyDiscount(String raw) {
    final amount = double.tryParse(raw.trim());

    if (amount == null || amount <= 0) {
      _discountError = 'Enter an amount greater than 0.';
    } else if ((amount * 100).round() > (subtotal * 100).round()) {
      _discountError =
          'Discount can’t be more than the subtotal (₹${subtotal.toStringAsFixed(2)}).';
    } else {
      _discount = double.parse(amount.toStringAsFixed(2));
      _discountError = null;
    }
    notifyListeners();
  }

  void removeDiscount() {
    if (_discount == 0 && _discountError == null) return;
    _discount = 0;
    _discountError = null;
    notifyListeners();
  }

  List<OrderItemRequest> get _items => [
    for (final line in cart.lines)
      OrderItemRequest(bookId: line.book.id, quantity: line.quantity),
  ];

  /// Places the order and, only once the server accepted it, empties the
  /// cart. Throws [ApiFailure] — the cart is left alone so nothing is lost.
  Future<PlacedOrder> placeOrder() async {
    if (_isPlacing) {
      throw const ApiFailure('Your order is already being placed.');
    }

    final customerId = _customerId;
    if (customerId == null) {
      throw const ApiFailure('Enter the customer’s details first.');
    }

    _isPlacing = true;
    notifyListeners();
    try {
      final order = await repository.placeOrder(
        _items,
        customerId: customerId,
        discount: _discount,
      );
      _lastOrder = order;
      cart.clear();
      return order;
    } finally {
      _isPlacing = false;
      notifyListeners();
    }
  }
}

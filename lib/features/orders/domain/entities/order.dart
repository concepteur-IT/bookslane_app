/// One cart line as the API wants it: which book and how many. The price is
/// deliberately absent — the server reads it from the catalogue.
class OrderItemRequest {
  const OrderItemRequest({required this.bookId, required this.quantity});

  /// [ShopBook.id], e.g. `store-12`.
  final String bookId;
  final int quantity;

  Map<String, dynamic> toJson() => {'book_id': bookId, 'quantity': quantity};
}

/// Who the order is for, as the seller typed it at checkout.
class CustomerDetails {
  const CustomerDetails({
    required this.name,
    required this.mobile,
    this.email = '',
    this.address = '',
  });

  /// Full name; the server splits it into first and last name.
  final String name;
  final String mobile;
  final String email;
  final String address;

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile': mobile,
    // Blank optional fields are left out — the API treats them as absent.
    if (email.isNotEmpty) 'email': email,
    if (address.isNotEmpty) 'address': address,
  };

  @override
  bool operator ==(Object other) =>
      other is CustomerDetails &&
      other.name == name &&
      other.mobile == mobile &&
      other.email == email &&
      other.address == address;

  @override
  int get hashCode => Object.hash(name, mobile, email, address);
}

/// An order the server has accepted.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.orderNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
  });

  final String id;
  final String orderNumber;
  final double subtotal;
  final double discountAmount;
  final double total;
}

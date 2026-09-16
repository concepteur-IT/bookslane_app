import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// The publisher's catalogue, stated without reference to HTTP or JSON.
///
/// Every method throws [ApiFailure] and nothing else.
abstract interface class ProductsRepository {
  /// One page of the signed-in publisher's products.
  Future<ProductPage> fetchProducts({
    required int page,
    int limit,
    String? search,
    ProductFilter filter,
    ProductSort sort,
  });

  /// Sets a product's stock to [quantity] and returns the updated product.
  ///
  /// [quantity] is the **new total**, not an amount to add — the API replaces
  /// the stored value, and the legacy thinkerslane quantity column with it.
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  });
}

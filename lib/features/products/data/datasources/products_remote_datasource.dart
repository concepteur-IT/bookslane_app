import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/features/products/data/models/product_model.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';

/// Talks to `/v1/products`. Knows about HTTP and JSON, and nothing else.
///
/// Every route is guarded, so every call needs the bearer token that
/// `AuthInterceptor` attaches.
class ProductsRemoteDataSource {
  const ProductsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String _path = '/products';

  Future<ProductPageModel> list({
    required int page,
    required int limit,
    String? search,
    ProductFilters filters = ProductFilters.initial,
    ProductSort sort = ProductSort.initial,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      _path,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort.field,
        'order': sort.order,
        // Omitted rather than sent empty: the pipe runs with
        // forbidNonWhitelisted, and an empty search would match nothing.
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (filters.isActive != null) 'is_active': filters.isActive! ? 1 : 0,
        if (filters.inStockOnly) 'in_stock': 1,
        if (filters.category != null) 'category_id': filters.category!.id,
      },
    );

    return ProductPageModel.fromJson(_asJsonObject(response.data));
  }

  /// The categories the caller's products are filed under.
  Future<List<ProductCategory>> categories() async {
    final response = await apiClient.dio.get<dynamic>('$_path/categories');
    final data = _asJsonObject(response.data)['data'];
    if (data is! List) {
      throw const FormatException('Category list is missing "data".');
    }

    return [
      for (final row in data)
        if (row is Map<String, dynamic>)
          ProductCategory(
            id: ProductModel.asInt(row['id']),
            name: ProductModel.asString(row['name']).trim(),
            productCount: ProductModel.asInt(row['product_count']),
          ),
    ];
  }

  /// Sets the product's stock to [quantity] — an absolute value, not a delta —
  /// and returns the updated product.
  Future<ProductModel> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    final response = await apiClient.dio.patch<dynamic>(
      '$_path/$productId/quantity',
      data: {'quantity': quantity},
    );

    return ProductModel.fromJson(_asJsonObject(response.data));
  }

  Map<String, dynamic> _asJsonObject(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API.');
    }
    return body;
  }
}

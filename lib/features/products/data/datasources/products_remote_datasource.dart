import 'package:bookslane_app/core/filters/catalog_filters.dart';
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
    CatalogFilters filters = const CatalogFilters(),
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
        ..._filterQuery(filters),
      },
    );

    return ProductPageModel.fromJson(_asJsonObject(response.data));
  }

  /// What the filter panel can offer if the user keeps [filters] (and the
  /// current [search]) — counts per option, from `GET /v1/products/filters`.
  Future<FilterFacets> filterFacets({
    required CatalogFilters filters,
    String? search,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      '$_path/filters',
      queryParameters: <String, dynamic>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        ..._filterQuery(filters),
      },
    );

    return FilterFacets.fromJson(_asJsonObject(response.data));
  }

  /// The filters My Publishings has: status, stock and category. The list and
  /// the `/filters` endpoint take the same params.
  Map<String, dynamic> _filterQuery(CatalogFilters filters) => filters.toQuery(
    categoryKey: 'category_id',
    statusKey: 'is_active',
    includeLanguages: false,
    includePrice: false,
  );

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

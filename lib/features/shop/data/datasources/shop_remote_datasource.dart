import 'package:bookslane_app/core/config/api_endpoints.dart';
import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/features/shop/data/models/shop_book_model.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

/// Talks to `/v1/shop`. Knows about HTTP and JSON, and nothing else.
///
/// Guarded, so every call needs the bearer token that `AuthInterceptor`
/// attaches.
class ShopRemoteDataSource {
  const ShopRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<ShopBookPageModel> list({
    required int page,
    required int limit,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ShopSort sort = ShopSort.initial,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiEndpoints.shopBooks,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': sort.value,
        ..._searchQuery(search),
        ..._filterQuery(filters),
      },
    );

    return ShopBookPageModel.fromJson(_asJsonObject(response.data));
  }

  /// What the filter panel can offer if the user keeps [filters] (and the
  /// current [search]) — counts per option, from `GET /v1/shop/filters`. Takes
  /// the list's filter params, so "show N" matches what the list will show.
  Future<FilterFacets> filterFacets({
    required CatalogFilters filters,
    String? search,
  }) async {
    final response = await apiClient.dio.get<dynamic>(
      ApiEndpoints.shopFilters,
      queryParameters: <String, dynamic>{
        ..._searchQuery(search),
        ..._filterQuery(filters),
      },
    );

    return FilterFacets.fromJson(_asJsonObject(response.data));
  }

  /// The Shop has every filter: status, stock, category, language and price.
  Map<String, dynamic> _filterQuery(CatalogFilters filters) =>
      filters.toQuery(categoryKey: 'category', statusKey: 'is_active');

  /// Omitted rather than sent empty: the pipe runs with forbidNonWhitelisted,
  /// and an empty search would match nothing.
  Map<String, dynamic> _searchQuery(String? search) => {
    if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
  };

  Map<String, dynamic> _asJsonObject(Object? body) {
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API.');
    }
    return body;
  }
}

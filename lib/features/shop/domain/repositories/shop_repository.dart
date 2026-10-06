import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

/// The shop catalogue, stated without reference to HTTP or JSON.
///
/// Every method throws [ApiFailure] and nothing else.
abstract interface class ShopRepository {
  /// One page of the shop catalogue, narrowed and ordered on the server.
  Future<ShopBookPage> fetchBooks({
    required int page,
    int limit,
    String? search,
    CatalogFilters filters,
    ShopSort sort,
  });

  /// What the filter panel can offer if the user keeps [filters] and the
  /// current [search]: counts per option, the price range, and the total they
  /// would leave.
  Future<FilterFacets> fetchFilters(CatalogFilters filters, {String? search});
}

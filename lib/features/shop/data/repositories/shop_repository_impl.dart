import 'package:dio/dio.dart';

import 'package:bookslane_app/core/filters/catalog_filters.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';
import 'package:bookslane_app/features/shop/domain/repositories/shop_repository.dart';

class ShopRepositoryImpl implements ShopRepository {
  const ShopRepositoryImpl({required this.remoteDataSource});

  final ShopRemoteDataSource remoteDataSource;

  @override
  Future<ShopBookPage> fetchBooks({
    required int page,
    int limit = 20,
    String? search,
    CatalogFilters filters = const CatalogFilters(),
    ShopSort sort = ShopSort.initial,
  }) => _guarded(() async {
    final result = await remoteDataSource.list(
      page: page,
      limit: limit,
      search: search,
      filters: filters,
      sort: sort,
    );
    return result.toEntity();
  });

  @override
  Future<FilterFacets> fetchFilters(CatalogFilters filters, {String? search}) =>
      _guarded(
        () => remoteDataSource.filterFacets(filters: filters, search: search),
      );

  Future<T> _guarded<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

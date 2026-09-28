import 'package:dio/dio.dart';

import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:bookslane_app/features/products/domain/repositories/products_repository.dart';

/// Implements [ProductsRepository] against app-api.
///
/// This is where `DioException` stops: callers get an [ApiFailure] with a
/// message meant for a person and app-api's `errorCode` to switch on.
class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl({required this.remoteDataSource});

  final ProductsRemoteDataSource remoteDataSource;

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    int limit = 10,
    String? search,
    ProductFilters filters = ProductFilters.initial,
    ProductSort sort = ProductSort.initial,
  }) async {
    try {
      final result = await remoteDataSource.list(
        page: page,
        limit: limit,
        search: search,
        filters: filters,
        sort: sort,
      );
      return result.toEntity();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    try {
      return await remoteDataSource.categories();
    } on DioException catch (error) {
      throw mapDioException(error);
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }

  @override
  Future<Product> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    try {
      final result = await remoteDataSource.updateQuantity(
        productId: productId,
        quantity: quantity,
      );
      return result.toEntity();
    } on DioException catch (error) {
      final failure = mapDioException(error);
      // PRODUCT_NOT_FOUND is also what the API returns for a product owned by
      // someone else — deliberately indistinguishable.
      if (failure.errorCode == 'PRODUCT_NOT_FOUND') {
        throw const ApiFailure(
          'That product is no longer available.',
          errorCode: 'PRODUCT_NOT_FOUND',
          statusCode: 404,
        );
      }
      throw failure;
    } on FormatException {
      throw const ApiFailure(
        'The server sent something unexpected. Please try again.',
      );
    }
  }
}

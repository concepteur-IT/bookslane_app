import 'dart:convert';
import 'dart:typed_data';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/network/api_client.dart';
import 'package:bookslane_app/core/network/api_failure.dart';
import 'package:bookslane_app/core/storage/token_storage.dart';
import 'package:bookslane_app/features/products/data/datasources/products_remote_datasource.dart';
import 'package:bookslane_app/features/products/data/repositories/products_repository_impl.dart';
import 'package:bookslane_app/features/products/domain/entities/product.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token';
  @override
  Future<String?> readRefreshToken() async => 'refresh';
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> clear() async {}
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ({int status, Map<String, dynamic> body}) Function(RequestOptions)
  respond;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final result = respond(options);
    return ResponseBody.fromString(
      jsonEncode(result.body),
      result.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A row exactly as app-api's ProductDto serialises it.
Map<String, dynamic> productJson({
  int id = 3244,
  String name = 'Baitalik',
  int stock = 12,
  int isActive = 1,
  Object price = 250.0,
}) => {
  'id': id,
  'type': 1,
  'name': name,
  'author': 'Rabindranath Tagore',
  'author_slug': 'rabindranath-tagore',
  'image': '2021/02/Baitalik.jpg',
  'image_url': 'https://cdn.example.com/2021/02/Baitalik.jpg',
  'code': 'BK-3244',
  'isbn_number': '9788126',
  'category_id': 4,
  'short_description': '',
  'description': '',
  'price': price,
  'offered_price': 200.0,
  'app_discounted_price': 190.0,
  'in_stock': stock > 0,
  'stock': stock,
  'stock_count': stock,
  'total_stock': stock,
  'language': 'Bengali',
  'binding': 'Hardcover',
  'page_number': 220,
  'publish_year': 2021,
  'publish_date': '2021-02-01',
  'views': 10,
  'is_active': isActive,
  'status': 1,
  'publisher': {
    'id': 9,
    'name': 'Thinkerslane',
    'slug': 'thinkerslane',
    'discount_rate': 10,
  },
  'created_at': '2021-02-01T00:00:00.000Z',
  'updated_at': '2026-09-01T00:00:00.000Z',
};

Map<String, dynamic> listJson(
  List<Map<String, dynamic>> rows, {
  int page = 1,
  int total = 1,
  int totalPages = 1,
  bool hasNext = false,
}) => {
  'data': rows,
  'pagination': {
    'page': page,
    'limit': 10,
    'total': total,
    'total_pages': totalPages,
    'has_next': hasNext,
  },
  'publishers': [
    {'id': 9, 'name': 'Thinkerslane', 'slug': 'thinkerslane', 'discount_rate': 10},
  ],
};

void main() {
  ({ProductsRepositoryImpl repo, FakeAdapter adapter}) build(
    ({int status, Map<String, dynamic> body}) Function(RequestOptions) respond,
  ) {
    final adapter = FakeAdapter(respond);
    final api = ApiClient(
      config: AppConfig.current.copyWith(enableLogging: false),
      storage: FakeTokenStorage(),
    );
    api.dio.httpClientAdapter = adapter;
    return (
      repo: ProductsRepositoryImpl(
        remoteDataSource: ProductsRemoteDataSource(apiClient: api),
      ),
      adapter: adapter,
    );
  }

  group('fetchProducts', () {
    test('parses the real list payload', () async {
      final t = build(
        (_) => (status: 200, body: listJson([productJson()], total: 1)),
      );

      final page = await t.repo.fetchProducts(page: 1);

      expect(page.items, hasLength(1));
      expect(page.items.first.id, 3244);
      expect(page.items.first.name, 'Baitalik');
      expect(page.items.first.stock, 12);
      expect(page.items.first.isActive, isTrue);
      expect(page.items.first.publisherName, 'Thinkerslane');
      expect(page.total, 1);
      expect(page.hasNext, isFalse);
    });

    test('sends the query app-api expects', () async {
      final t = build((_) => (status: 200, body: listJson([])));

      await t.repo.fetchProducts(
        page: 2,
        limit: 10,
        search: '  tagore  ',
        filter: ProductFilter.inactive,
        sort: ProductSort.quantity,
      );

      final query = t.adapter.requests.single.queryParameters;
      expect(query['page'], 2);
      expect(query['limit'], 10);
      expect(query['search'], 'tagore'); // trimmed
      expect(query['is_active'], 0);
      expect(query['sort'], 'stock');
      expect(query['order'], 'DESC');
    });

    test('omits search and is_active when not set', () async {
      final t = build((_) => (status: 200, body: listJson([])));

      await t.repo.fetchProducts(page: 1, search: '   ');

      final query = t.adapter.requests.single.queryParameters;
      expect(query.containsKey('search'), isFalse);
      expect(query.containsKey('is_active'), isFalse);
    });

    test('tolerates legacy rows sending numbers as strings', () async {
      final row = productJson()
        ..['stock'] = '45'
        ..['price'] = '199.50'
        ..['is_active'] = '0';
      final t = build((_) => (status: 200, body: listJson([row])));

      final page = await t.repo.fetchProducts(page: 1);

      expect(page.items.first.stock, 45);
      expect(page.items.first.price, 199.50);
      expect(page.items.first.isActive, isFalse);
    });

    test('maps a 503 to its message', () async {
      final t = build(
        (_) => (
          status: 503,
          body: {
            'statusCode': 503,
            'message': 'The product catalogue is temporarily unavailable.',
            'errorCode': 'CATALOGUE_UNAVAILABLE',
          },
        ),
      );

      await expectLater(
        t.repo.fetchProducts(page: 1),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.errorCode, 'errorCode', 'CATALOGUE_UNAVAILABLE')
              .having(
                (f) => f.message,
                'message',
                'The product catalogue is temporarily unavailable.',
              ),
        ),
      );
    });
  });

  group('updateQuantity', () {
    test('PATCHes the absolute total to the right URL', () async {
      final t = build(
        (_) => (status: 200, body: productJson(stock: 37)),
      );

      final product = await t.repo.updateQuantity(
        productId: 3244,
        quantity: 37,
      );

      final request = t.adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/products/3244/quantity');
      expect(request.data, {'quantity': 37});
      expect(product.stock, 37);
    });

    test('a product the caller does not own reads as not found', () async {
      final t = build(
        (_) => (
          status: 404,
          body: {
            'statusCode': 404,
            'message': 'Product not found.',
            'errorCode': 'PRODUCT_NOT_FOUND',
          },
        ),
      );

      await expectLater(
        t.repo.updateQuantity(productId: 1, quantity: 5),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.errorCode, 'errorCode', 'PRODUCT_NOT_FOUND')
              .having((f) => f.isNotFound, 'isNotFound', isTrue),
        ),
      );
    });

    test('surfaces the validation message on a rejected quantity', () async {
      final t = build(
        (_) => (
          status: 400,
          body: {
            'statusCode': 400,
            'message': 'quantity cannot be negative.',
          },
        ),
      );

      await expectLater(
        t.repo.updateQuantity(productId: 3244, quantity: -1),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.message,
            'message',
            'quantity cannot be negative.',
          ),
        ),
      );
    });
  });
}

import 'package:bookslane_app/core/network/json_coerce.dart';
import 'package:bookslane_app/features/shop/domain/entities/shop_book.dart';

/// Wire format of app-api's `ShopBookDto`.
class ShopBookModel {
  const ShopBookModel({
    required this.id,
    required this.source,
    required this.refId,
    required this.name,
    required this.author,
    required this.code,
    required this.price,
    required this.sellingPrice,
    required this.stock,
    this.isActive = true,
    this.imageUrl,
    this.language = '',
    this.binding = '',
    this.isbn = '',
    this.publisherName = '',
    this.pageCount = 0,
    this.publishYear,
    this.categories = const [],
    this.description = '',
  });

  final String id;
  final String source;
  final int refId;
  final String name;
  final String author;
  final String code;
  final double price;
  final double sellingPrice;
  final int stock;
  final bool isActive;
  final String? imageUrl;
  final String language;
  final String binding;
  final String isbn;
  final String publisherName;
  final int pageCount;
  final int? publishYear;
  final List<String> categories;
  final String description;

  factory ShopBookModel.fromJson(Map<String, dynamic> json) {
    final image = json['image_url'];
    final price = jsonDouble(json['price']);
    final selling = jsonDouble(json['selling_price']);

    final source = jsonString(json['source']);
    final refId = jsonInt(json['ref_id']);

    return ShopBookModel(
      // Ids are unique across both shelves ("publishing-3244"). An old server
      // sent a bare number; keep it usable rather than blank the row.
      id: jsonString(json['id']).isNotEmpty
          ? jsonString(json['id'])
          : '$source-$refId',
      source: source,
      refId: refId,
      name: jsonString(json['name']).trim(),
      author: jsonString(json['author']).trim(),
      code: jsonString(json['code']).trim(),
      price: price,
      // An old server without selling_price: fall back to the list price
      // rather than showing ₹0.
      sellingPrice: selling > 0 ? selling : price,
      stock: jsonInt(json['stock']),
      // Absent from an old server: treat as active rather than tag it.
      isActive: json['is_active'] == null || jsonInt(json['is_active']) == 1,
      imageUrl: image is String && image.isNotEmpty ? image : null,
      language: jsonString(json['language']).trim(),
      binding: jsonString(json['binding']).trim(),
      isbn: jsonString(json['isbn']).trim(),
      publisherName: jsonString(json['publisher_name']).trim(),
      pageCount: jsonInt(json['page_count']),
      publishYear: jsonInt(json['publish_year']) > 0
          ? jsonInt(json['publish_year'])
          : null,
      categories: [
        if (json['categories'] is List)
          for (final c in json['categories'] as List) jsonString(c),
      ],
      description: _plainText(json['description']),
    );
  }

  ShopBook toEntity() => ShopBook(
    id: id,
    source: ShopSource.fromWire(source),
    refId: refId,
    title: name,
    author: author,
    sku: code,
    mrp: price,
    price: sellingPrice,
    stock: stock,
    isActive: isActive,
    imageUrl: imageUrl,
    language: language,
    binding: binding,
    isbn: isbn,
    publisherName: publisherName,
    pageCount: pageCount,
    publishYear: publishYear,
    categories: categories,
    description: description,
  );
}

/// thinkerslane stores descriptions as HTML. Paragraphs and line breaks become
/// newlines, every other tag is dropped and the common entities decoded.
String _plainText(Object? value) {
  final html = jsonString(value);
  if (html.isEmpty) return '';

  return html
      .replaceAll(RegExp(r'</p>|</div>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<br\s*/?>|</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      // Last, so '&amp;lt;' stays the literal text '&lt;'.
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Wire format of the shop list response — `data` plus the `pagination` block.
class ShopBookPageModel {
  const ShopBookPageModel({required this.items, required this.pagination});

  final List<ShopBookModel> items;
  final Map<String, dynamic> pagination;

  factory ShopBookPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('Shop list is missing "data".');
    }

    return ShopBookPageModel(
      items: [
        for (final row in data)
          if (row is Map<String, dynamic>) ShopBookModel.fromJson(row),
      ],
      pagination: json['pagination'] is Map<String, dynamic>
          ? json['pagination'] as Map<String, dynamic>
          : const {},
    );
  }

  ShopBookPage toEntity() => ShopBookPage(
    items: [for (final item in items) item.toEntity()],
    page: jsonInt(pagination['page']),
    limit: jsonInt(pagination['limit']),
    total: jsonInt(pagination['total']),
    totalPages: jsonInt(pagination['total_pages']),
    hasNext: pagination['has_next'] == true,
  );
}

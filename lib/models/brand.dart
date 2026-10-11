import '../utils/format.dart';
import 'product.dart';

class Brand {
  final int id;
  final String name;
  final String? logo;
  final int productCount;
  final List<Product> products;

  Brand({
    required this.id,
    required this.name,
    this.logo,
    this.productCount = 0,
    this.products = const [],
  });

  factory Brand.fromJson(Map<String, dynamic> j) {
    final products = ((j['products'] ?? []) as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    return Brand(
      id: toInt(j['id']),
      name: (j['name'] ?? '').toString(),
      logo: (j['logo'] == null || j['logo'].toString().isEmpty)
          ? null
          : j['logo'].toString(),
      productCount: j['product_count'] != null
          ? toInt(j['product_count'])
          : products.length,
      products: products,
    );
  }
}

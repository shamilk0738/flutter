import '../utils/format.dart';
import 'scheme.dart';

class Product {
  final int id;
  final int brand;
  final String brandName;
  final String name;
  final String description;
  final String? image;
  final double price; // per piece
  final int piecesPerBag;
  final double bagRate;
  final List<Scheme> schemes;

  Product({
    required this.id,
    required this.brand,
    required this.brandName,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.piecesPerBag,
    required this.bagRate,
    required this.schemes,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: toInt(j['id']),
        brand: toInt(j['brand']),
        brandName: (j['brand_name'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        image: (j['image'] == null || j['image'].toString().isEmpty)
            ? null
            : j['image'].toString(),
        price: toDouble(j['price']),
        piecesPerBag: toInt(j['pieces_per_bag']),
        bagRate: toDouble(j['bag_rate']),
        schemes: ((j['schemes'] ?? []) as List)
            .map((e) => Scheme.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<Scheme> schemesFor(String unit) =>
      schemes.where((s) => s.unit == unit).toList();
}

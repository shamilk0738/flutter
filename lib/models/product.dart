import '../utils/format.dart';
import 'scheme.dart';

class Product {
  final int id;
  final int brand;
  final int brandId;
  final String brandName;
  final String name;
  final String description;
  final String? image;
  final double mrp; // printed MRP per piece
  final double price; // per piece
  final int piecesPerBag;
  final double bagRate; // ഒരു bag-ന്റെ മുഴുവൻ വില (server-ൽ നിന്ന്)
  final int stock; // ആകെ pieces
  final int stockBags;
  final int stockPieces;
  final List<Scheme> schemes;

  Product({
    required this.id,
    required this.brand,
    required this.brandName,
    required this.brandId,
    required this.name,
    required this.description,
    required this.image,
    required this.mrp,
    required this.price,
    required this.piecesPerBag,
    required this.bagRate,
    required this.stock,
    required this.stockBags,
    required this.stockPieces,
    required this.schemes,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: toInt(j['id']),
    brand: toInt(j['brand']),
    brandId: (j['brand'] as num?)?.toInt() ?? 0,
    brandName: (j['brand_name'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: (j['description'] ?? '').toString(),
    image: (j['image'] == null || j['image'].toString().isEmpty)
        ? null
        : j['image'].toString(),
    mrp: toDouble(j['mrp']),
    price: toDouble(j['price']),
    piecesPerBag: toInt(j['pieces_per_bag']),
    bagRate: toDouble(j['bag_rate']),
    stock: toInt(j['stock']),
    stockBags: toInt(j['stock_bags']),
    stockPieces: toInt(j['stock_pieces']),
    schemes: ((j['schemes'] ?? []) as List)
        .map((e) => Scheme.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  List<Scheme> schemesFor(String unit) =>
      schemes.where((s) => s.unit == unit).toList();

  /// ഒരു bag-ന്റെ മുഴുവൻ വില (ഗുണിക്കേണ്ട)
  double get bagPrice => bagRate;

  /// Bag എടുക്കുമ്പോൾ ഒരു piece-ന്റെ വില
  double get bagPieceRate => bagRate / (piecesPerBag > 0 ? piecesPerBag : 1);

  /// ഒരു unit-ന്റെ rate
  double rateFor(String unit) => unit == 'bag' ? bagPrice : price;

  /// ആ unit-ൽ പരമാവധി എടുക്കാവുന്ന quantity (stock അനുസരിച്ച്)
  int maxQtyFor(String unit) {
    if (unit == 'bag') {
      final per = piecesPerBag > 0 ? piecesPerBag : 1;
      return stock ~/ per;
    }
    return stock;
  }
}

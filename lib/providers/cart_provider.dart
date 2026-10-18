import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartLine {
  final Product product;
  final String unit;
  int quantity;
  CartLine(this.product, this.unit, this.quantity);

  double get rate => product.rateFor(unit);
  double get total => rate * quantity;
}

class CartProvider extends ChangeNotifier {
  int? shopId;
  String shopName = '';
  final Map<String, CartLine> _lines = {};

  final Set<int> _submittedBrands = {};

  int? editingOrderId;
  bool get isEditing => editingOrderId != null;

  String _key(int productId, String unit) => '$productId-$unit';

  void startShop(int id, String name) {
    if (shopId == id) return;
    shopId = id;
    shopName = name;
    editingOrderId = null;
    _lines.clear();
    _submittedBrands.clear();
    notifyListeners();
  }

  void startEdit({
    required int orderId,
    required int shopId,
    required String shopName,
    required List<CartLine> lines,
  }) {
    this.shopId = shopId;
    this.shopName = shopName;
    editingOrderId = orderId;
    _lines.clear();
    _submittedBrands.clear();
    for (final l in lines) {
      _lines[_key(l.product.id, l.unit)] = l;
      _submittedBrands.add(l.product.brand);
    }
    notifyListeners();
  }

  int qty(Product p, String unit) => _lines[_key(p.id, unit)]?.quantity ?? 0;

  void setQty(Product p, String unit, int q) {
    final k = _key(p.id, unit);
    if (q <= 0) {
      _lines.remove(k);
    } else {
      _lines[k] = CartLine(p, unit, q);
    }

    _submittedBrands.remove(p.brand);
    notifyListeners();
  }

  void removeLine(CartLine l) {
    _lines.remove(_key(l.product.id, l.unit));
    notifyListeners();
  }

  List<CartLine> get lines => _lines.values.toList();
  int get itemCount => _lines.length;
  double get total => _lines.values.fold(0.0, (s, l) => s + l.total);

  int brandCount(int brandId) =>
      _lines.values.where((l) => l.product.brand == brandId).length;

  double brandTotal(int brandId) => _lines.values
      .where((l) => l.product.brand == brandId)
      .fold(0.0, (s, l) => s + l.total);

  void submitBrand(int brandId) {
    _submittedBrands.add(brandId);
    notifyListeners();
  }

  bool isBrandSubmitted(int brandId) => _submittedBrands.contains(brandId);

  Map<int, List<CartLine>> get linesByBrand {
    final map = <int, List<CartLine>>{};
    for (final l in _lines.values) {
      map.putIfAbsent(l.product.brand, () => []).add(l);
    }
    return map;
  }

  void clear() {
    _lines.clear();
    _submittedBrands.clear();
    shopId = null;
    shopName = '';
    editingOrderId = null;
    notifyListeners();
  }
}

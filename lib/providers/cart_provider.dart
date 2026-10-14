import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartLine {
  final Product product;
  final String unit; // 'bag' അല്ലെങ്കിൽ 'piece'
  int quantity;
  CartLine(this.product, this.unit, this.quantity);

  double get rate => unit == 'bag' ? product.bagRate : product.price;
  double get total => rate * quantity;
}

class CartProvider extends ChangeNotifier {
  int? shopId;
  String shopName = '';
  final Map<String, CartLine> _lines = {};

  String _key(int productId, String unit) => '$productId-$unit';

  /// Shop click ചെയ്യുമ്പോൾ വിളിക്കുക. മറ്റൊരു shop ആണെങ്കിൽ cart ശൂന്യമാകും.
  void startShop(int id, String name) {
    if (shopId == id) return;
    shopId = id;
    shopName = name;
    _lines.clear();
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
    notifyListeners();
  }

  void removeLine(CartLine l) {
    _lines.remove(_key(l.product.id, l.unit));
    notifyListeners();
  }

  List<CartLine> get lines => _lines.values.toList();
  int get itemCount => _lines.length;
  double get total => _lines.values.fold(0.0, (s, l) => s + l.total);

  /// ഒരു brand-ൽ നിന്ന് എത്ര items എടുത്തു (brand card-ൽ badge കാണിക്കാൻ)
  int brandCount(int brandId) =>
      _lines.values.where((l) => l.product.brand == brandId).length;

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

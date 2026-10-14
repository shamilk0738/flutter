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

  /// Submit ചെയ്ത brands (brand id)
  final Set<int> _submittedBrands = {};

  /// Edit mode: ഏത് order ആണ് edit ചെയ്യുന്നത് (null ആണെങ്കിൽ പുതിയ order)
  int? editingOrderId;
  bool get isEditing => editingOrderId != null;

  String _key(int productId, String unit) => '$productId-$unit';

  /// Shop select ചെയ്യുമ്പോൾ വിളിക്കുക. മറ്റൊരു shop ആണെങ്കിൽ cart ശൂന്യമാകും.
  void startShop(int id, String name) {
    if (shopId == id) return;
    shopId = id;
    shopName = name;
    editingOrderId = null;
    _lines.clear();
    _submittedBrands.clear();
    notifyListeners();
  }

  /// ഒരു order edit ചെയ്യാൻ തുടങ്ങുമ്പോൾ വിളിക്കുക.
  /// നിലവിലെ items cart-ലേക്ക് നിറയ്ക്കും, shop ആ order-ന്റെ shop ആകും.
  /// ആ items-ന്റെ brands submitted ആയി mark ചെയ്യും.
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
    // quantity മാറ്റിയാൽ ആ brand വീണ്ടും submit ചെയ്യണം
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

  /// ഒരു brand-ൽ നിന്ന് എത്ര items എടുത്തു (brand card-ൽ badge കാണിക്കാൻ)
  int brandCount(int brandId) =>
      _lines.values.where((l) => l.product.brand == brandId).length;

  /// ഒരു brand-ന്റെ തുക
  double brandTotal(int brandId) => _lines.values
      .where((l) => l.product.brand == brandId)
      .fold(0.0, (s, l) => s + l.total);

  /// Brand "Submit" അമർത്തിയപ്പോൾ
  void submitBrand(int brandId) {
    _submittedBrands.add(brandId);
    notifyListeners();
  }

  bool isBrandSubmitted(int brandId) => _submittedBrands.contains(brandId);

  /// Brand-wise group ചെയ്ത lines (ബില്ലിന്)
  Map<int, List<CartLine>> get linesByBrand {
    final map = <int, List<CartLine>>{};
    for (final l in _lines.values) {
      map.putIfAbsent(l.product.brand, () => []).add(l);
    }
    return map;
  }

  /// Order place ചെയ്ത ശേഷം / logout-ൽ shop ഉൾപ്പെടെ മായ്ക്കുന്നു
  void clear() {
    _lines.clear();
    _submittedBrands.clear();
    shopId = null;
    shopName = '';
    editingOrderId = null;
    notifyListeners();
  }
}

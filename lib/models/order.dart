import '../utils/format.dart';

class OrderItem {
  final int id;
  final int product; // product id
  final String productName;
  final String unit;
  final int quantity;
  final double unitPrice;
  final int freeQuantity;
  final double discountPercent;
  final double lineTotal;

  OrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.freeQuantity,
    required this.discountPercent,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: toInt(j['id']),
    product: toInt(j['product']),
    productName: (j['product_name'] ?? '').toString(),
    unit: (j['unit'] ?? '').toString(),
    quantity: toInt(j['quantity']),
    unitPrice: toDouble(j['unit_price']),
    freeQuantity: toInt(j['free_quantity']),
    discountPercent: toDouble(j['discount_percent']),
    lineTotal: toDouble(j['line_total']),
  );
}

class Order {
  final int id;
  final int shop;
  final String shopName;
  final int salesman;
  final String salesmanName;
  final String status;
  final String notes;
  final double totalAmount;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.shop,
    required this.shopName,
    required this.salesman,
    required this.salesmanName,
    required this.status,
    required this.notes,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: toInt(j['id']),
    shop: toInt(j['shop']),
    shopName: (j['shop_name'] ?? '').toString(),
    salesman: toInt(j['salesman']),
    salesmanName: (j['salesman_name'] ?? '').toString(),
    status: (j['status'] ?? 'pending').toString(),
    notes: (j['notes'] ?? '').toString(),
    totalAmount: toDouble(j['total_amount']),
    createdAt: (j['created_at'] ?? '').toString(),
    items: ((j['items'] ?? []) as List)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
int _i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

class DayPoint {
  final String date; // yyyy-MM-dd
  final double total;
  final int count;
  DayPoint({required this.date, required this.total, required this.count});

  factory DayPoint.fromJson(Map<String, dynamic> j) => DayPoint(
    date: '${j['date']}',
    total: _d(j['total']),
    count: _i(j['count']),
  );
}

class ShopRow {
  final String name;
  final int count;
  final double total;
  ShopRow({required this.name, required this.count, required this.total});

  factory ShopRow.fromJson(Map<String, dynamic> j) => ShopRow(
    name: '${j['name'] ?? ''}',
    count: _i(j['count']),
    total: _d(j['total']),
  );
}

class ProductRow {
  final String name;
  final String brand;
  final int qty;
  final int free;
  final double amount;
  ProductRow({
    required this.name,
    required this.brand,
    required this.qty,
    required this.free,
    required this.amount,
  });

  factory ProductRow.fromJson(Map<String, dynamic> j) => ProductRow(
    name: '${j['name'] ?? ''}',
    brand: '${j['brand'] ?? ''}',
    qty: _i(j['qty']),
    free: _i(j['free']),
    amount: _d(j['amount']),
  );
}

/// Salesman-ന്റെ സ്വന്തം sales report
class MyReport {
  final double total;
  final int count;
  final List<DayPoint> byDay;
  final List<ShopRow> byShop;
  final List<ProductRow> byProduct;

  MyReport({
    required this.total,
    required this.count,
    required this.byDay,
    required this.byShop,
    required this.byProduct,
  });

  factory MyReport.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((j[key] ?? []) as List)
            .map((e) => f(e as Map<String, dynamic>))
            .toList();

    return MyReport(
      total: _d(j['total']),
      count: _i(j['count']),
      byDay: list('by_day', DayPoint.fromJson),
      byShop: list('by_shop', ShopRow.fromJson),
      byProduct: list('by_product', ProductRow.fromJson),
    );
  }
}

import '../models/app_user.dart';
import '../models/attendance.dart';
import '../models/brand.dart';
import '../models/my_report.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/salesman_report.dart';
import '../models/shop.dart';
import '../utils/format.dart';
import 'api_service.dart';

/// എല്ലാ API endpoints ഇവിടെ. Screens ഇത് മാത്രം വിളിക്കും.
class Repository {
  Repository._();
  static final Repository instance = Repository._();
  final ApiService _api = ApiService.instance;

  // ---------- Auth ----------
  /// Login ചെയ്ത് tokens സൂക്ഷിക്കുന്നു
  Future<AppUser> login(String username, String password) async {
    final data = await _api.post(
      '/auth/login/',
      auth: false,
      body: {'username': username, 'password': password},
    );
    await _api.saveTokens(
      access: data['access'].toString(),
      refresh: data['refresh'].toString(),
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final data = await _api.get('/me/');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Attendance ----------
  Future<List<Attendance>> attendance({DateTime? date}) async {
    final data = await _api.get(
      '/attendance/',
      query: {'date': date == null ? null : apiDate(date)},
    );
    return _api
        .asList(data)
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Brands & Products ----------
  Future<List<Brand>> brands() async {
    final data = await _api.get('/brands/');
    return _api
        .asList(data)
        .map((e) => Brand.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Brand> brand(int id) async {
    final data = await _api.get('/brands/$id/');
    return Brand.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Product>> products({int? brand, String? q}) async {
    final data = await _api.get(
      '/products/',
      query: {'brand': brand?.toString(), 'q': q},
    );
    return _api
        .asList(data)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Shops ----------
  Future<List<Shop>> shops({String? q, String? district}) async {
    final data = await _api.get(
      '/shops/',
      query: {'q': q, 'district': district},
    );
    return _api
        .asList(data)
        .map((e) => Shop.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Shop> createShop(Map<String, dynamic> body) async {
    final data = await _api.post('/shops/', body: body);
    return Shop.fromJson(data as Map<String, dynamic>);
  }

  Future<Shop> updateShop(int id, Map<String, dynamic> body) async {
    final data = await _api.patch('/shops/$id/', body: body);
    return Shop.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteShop(int id) async {
    await _api.delete('/shops/$id/');
  }

  // ---------- Orders ----------
  Future<List<Order>> orders({int? shop, String? status}) async {
    final data = await _api.get(
      '/orders/',
      query: {'shop': shop?.toString(), 'status': status},
    );
    return _api
        .asList(data)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> order(int id) async {
    final data = await _api.get('/orders/$id/');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  /// items: [{product, unit, quantity}]
  Future<Order> createOrder({
    required int shop,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _api.post(
      '/orders/',
      body: {'shop': shop, 'notes': notes, 'items': items},
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  /// Pending order-ന്റെ items / notes മാറ്റാൻ. items: [{product, unit, quantity}]
  Future<Order> updateOrder(
    int id, {
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await _api.patch(
      '/orders/$id/edit/',
      body: {'notes': notes, 'items': items},
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<Order> updateOrderStatus(int id, String status) async {
    final data = await _api.patch('/orders/$id/', body: {'status': status});
    return Order.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Report ----------
  Future<List<SalesmanReport>> salesmanPerformance({
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await _api.get(
      '/reports/salesman-performance/',
      query: {
        'from': from == null ? null : apiDate(from),
        'to': to == null ? null : apiDate(to),
      },
    );
    final list = (data['salesmen'] ?? []) as List;
    return list
        .map((e) => SalesmanReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Login ചെയ്ത salesman-ന്റെ സ്വന്തം sales report
  Future<MyReport> mySummary({DateTime? from, DateTime? to}) async {
    final data = await _api.get(
      '/reports/my-summary/',
      query: {
        'from': from == null ? null : apiDate(from),
        'to': to == null ? null : apiDate(to),
      },
    );
    return MyReport.fromJson(data as Map<String, dynamic>);
  }
}

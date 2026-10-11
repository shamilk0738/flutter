import '../utils/format.dart';

class Shop {
  final int id;
  final String name;
  final String ownerName;
  final String phone;
  final String gstNumber;
  final String address;
  final String district;
  final String pincode;
  final int? route;
  final String routeName;
  final int? salesman;
  final String salesmanName;
  final bool isActive;

  Shop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.gstNumber,
    required this.address,
    required this.district,
    required this.pincode,
    required this.route,
    required this.routeName,
    required this.salesman,
    required this.salesmanName,
    required this.isActive,
  });

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: toInt(j['id']),
        name: (j['name'] ?? '').toString(),
        ownerName: (j['owner_name'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        gstNumber: (j['gst_number'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        district: (j['district'] ?? '').toString(),
        pincode: (j['pincode'] ?? '').toString(),
        route: j['route'] == null ? null : toInt(j['route']),
        routeName: (j['route_name'] ?? '').toString(),
        salesman: j['salesman'] == null ? null : toInt(j['salesman']),
        salesmanName: (j['salesman_name'] ?? '').toString(),
        isActive: j['is_active'] ?? true,
      );
}

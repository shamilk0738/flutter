import '../utils/format.dart';

class SalesmanReport {
  final int salesmanId;
  final String name;
  final String route;
  final int totalOrders;
  final double totalSales;
  final int shopsCovered;
  final int attendanceDays;
  final double monthlyTarget;
  final double targetAchievedPercent;

  SalesmanReport({
    required this.salesmanId,
    required this.name,
    required this.route,
    required this.totalOrders,
    required this.totalSales,
    required this.shopsCovered,
    required this.attendanceDays,
    required this.monthlyTarget,
    required this.targetAchievedPercent,
  });

  factory SalesmanReport.fromJson(Map<String, dynamic> j) => SalesmanReport(
        salesmanId: toInt(j['salesman_id']),
        name: (j['name'] ?? '').toString(),
        route: (j['route'] ?? '').toString(),
        totalOrders: toInt(j['total_orders']),
        totalSales: toDouble(j['total_sales']),
        shopsCovered: toInt(j['shops_covered']),
        attendanceDays: toInt(j['attendance_days']),
        monthlyTarget: toDouble(j['monthly_target']),
        targetAchievedPercent: toDouble(j['target_achieved_percent']),
      );
}

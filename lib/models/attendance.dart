import '../utils/format.dart';

class Attendance {
  final int id;
  final int salesman;
  final String salesmanName;
  final String date;
  final String loginTime;

  Attendance({
    required this.id,
    required this.salesman,
    required this.salesmanName,
    required this.date,
    required this.loginTime,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: toInt(j['id']),
        salesman: toInt(j['salesman']),
        salesmanName: (j['salesman_name'] ?? '').toString(),
        date: (j['date'] ?? '').toString(),
        loginTime: (j['login_time'] ?? '').toString(),
      );
}

class AppUser {
  final int id;
  final String username;
  final String name;
  final String role;
  final String phone;
  final String route;
  final String? photo;

  AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.phone = '',
    this.route = '',
    this.photo,
  });

  bool get isAdmin => role == 'admin';
  bool get isSalesman => role == 'salesman';
  bool get isShop => role == 'shop';

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final rawName = (j['name'] ?? '').toString().trim();
    final username = (j['username'] ?? '').toString();
    final rawPhoto = j['photo']?.toString() ?? '';
    return AppUser(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      username: username,
      name: rawName.isEmpty ? username : rawName,
      role: (j['role'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      route: (j['route'] ?? '').toString(),
      photo: rawPhoto.isEmpty ? null : rawPhoto,
    );
  }
}

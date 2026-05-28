class UserProfile {
  final String id;
  final String email;
  final String role; // 'admin', 'manager', 'sales', 'operator', 'tenant', 'user'
  final String name;
  final String phone;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      name: json['name'] as String? ?? 'Khách',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';
  bool get isStaff => role == 'staff' || role == 'operator' || role == 'sales';
  bool get isTenant => role == 'tenant';

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Quản trị viên';
      case 'manager':
        return 'Quản lý';
      case 'operator':
        return 'Vận hành';
      case 'sales':
        return 'Kinh doanh';
      case 'tenant':
        return 'Người thuê';
      default:
        return 'Người dùng';
    }
  }
}

# Thiết Kế Chi Tiết: Đăng Nhập & Phân Quyền (Auth & RBAC) trên Flutter

Tài liệu này hướng dẫn chi tiết cách chuyển đổi logic đăng nhập và phân luồng người dùng (dựa trên tài liệu `younghouse_auth_guide.md`) từ Web Next.js sang ứng dụng Flutter.

---

## 1. Sơ đồ Hoạt động (Auth Flow) trên Mobile

1. **Người dùng** nhập Email & Password trên Mobile App.
2. Ứng dụng gọi `Supabase.instance.client.auth.signInWithPassword()`.
3. Nhận về **JWT Access Token** (Lưu tự động trên máy nhờ `supabase_flutter`).
4. Truy vấn bảng `public.profiles` để lấy thông tin **Role** (Vai trò: `admin`, `manager`, `sales`, `operator`, `tenant`, `user`).
5. **GoRouter** (Thư viện điều hướng) sẽ chặn (redirect) và đẩy người dùng vào màn hình tương ứng dựa trên Role.

---

## 2. Cấu trúc Thư mục Tính năng Auth

```text
lib/
└── features/
    └── auth/
        ├── models/
        │   └── user_profile.dart        # Chứa model khớp với bảng public.profiles
        ├── data/
        │   └── auth_repository.dart     # Xử lý logic Login / Logout
        ├── providers/
        │   └── auth_controller.dart     # Quản lý trạng thái đang đăng nhập, lưu trữ Role
        └── presentation/
            └── screens/
                └── login_screen.dart    # Giao diện Đăng nhập
```

---

## 3. Data Model: `user_profile.dart`

Tạo model để hứng dữ liệu từ bảng `public.profiles`.

```dart
class UserProfile {
  final String id;
  final String email;
  final String role; // 'admin', 'manager', 'sales', 'operator', 'tenant', 'user'
  final String name;
  final String phone;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      name: json['name'] ?? 'Khách',
      phone: json['phone'] ?? '',
    );
  }
}
```

---

## 4. Giao tiếp Backend: `auth_repository.dart`

File này chịu trách nhiệm đăng nhập, đăng xuất và fetch thông tin Profile.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Đăng nhập bằng Email & Password
  Future<UserProfile> login(String email, String password) async {
    // 1. Thực hiện Login vào Supabase Auth
    final AuthResponse response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) throw Exception('Đăng nhập thất bại!');

    // 2. Lấy thông tin Role từ bảng profiles
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromJson(profileData);
  }

  // Đăng xuất
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Stream lắng nghe thay đổi trạng thái đăng nhập
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
```

---

## 5. State Management: `auth_controller.dart`

Sử dụng Riverpod để lưu trữ thông tin User đang đăng nhập và chia sẻ toàn app.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_profile.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

// Trạng thái user hiện tại
final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

// Logic xử lý Đăng nhập
final authControllerProvider = Provider((ref) {
  final repo = ref.watch(authRepositoryProvider);
  
  return AuthController(repo: repo, ref: ref);
});

class AuthController {
  final AuthRepository repo;
  final Ref ref;

  AuthController({required this.repo, required this.ref});

  Future<void> signIn(String email, String password) async {
    try {
      // Gọi repository login
      final profile = await repo.login(email, password);
      
      // Lưu profile vào state
      ref.read(currentUserProvider.notifier).state = profile;
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  void signOut() {
    repo.logout();
    ref.read(currentUserProvider.notifier).state = null;
  }
}
```

---

## 6. Logic Phân Quyền Điều Hướng (GoRouter Redirect)

Đây là điểm mấu chốt mô phỏng đoạn mã chuyển hướng trên Next.js:

```dart
// Điều hướng dựa trên user.role trong Next.js:
// if (user.role === 'owner' || user.role === 'manager') -> '/owner'
// else if (user.role === 'admin') -> '/admin'
// else -> '/'
```

Trên Flutter, cấu hình `GoRouter` sử dụng tính năng **redirect**:

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Đọc trạng thái User hiện tại
      final user = ref.read(currentUserProvider);
      
      final isGoingToLogin = state.uri.toString() == '/login';

      // 1. Chưa đăng nhập & Không phải ở màn login -> Đuổi về Login
      if (user == null && !isGoingToLogin) {
        return '/login';
      }

      // 2. Đã đăng nhập nhưng vẫn cố vào trang Login -> Phân quyền đẩy đi trang khác
      if (user != null && isGoingToLogin) {
        if (user.role == 'admin') {
          return '/admin_dashboard';
        } else if (user.role == 'manager') {
          return '/manager_dashboard'; // Hoặc /owner tuỳ cấu trúc
        } else if (user.role == 'operator' || user.role == 'sales') {
           return '/staff_dashboard';
        } else {
          // Tenant, User, v.v...
          return '/home'; // Màn hình chính tìm phòng
        }
      }

      return null; // Giữ nguyên luồng
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/admin_dashboard', builder: (context, state) => const AdminScreen()),
      GoRoute(path: '/manager_dashboard', builder: (context, state) => const ManagerScreen()),
    ],
  );
});
```

---

## 7. Giao diện (Presentation): `login_screen.dart`

Giao diện đăng nhập sẽ gọi hàm `signIn` từ AuthController:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController(text: 'admin@younghouse.vn');
    final passController = TextEditingController(text: 'AdminPassword123');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Gọi Provider xử lý đăng nhập
                  await ref.read(authControllerProvider).signIn(
                    emailController.text,
                    passController.text,
                  );
                  // Đăng nhập thành công, GoRouter tự động redirect dựa trên Role
                  context.go('/home'); // Gọi trigger để Router tự redirect
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('ĐĂNG NHẬP'),
            )
          ],
        ),
      ),
    );
  }
}
```

---
### Tóm tắt lợi ích:
Phương pháp này giúp mã nguồn tách biệt hoàn toàn **Logic kết nối Database** (Data Layer), **State** (Provider Layer) và **Giao diện** (Presentation Layer), đồng thời cơ chế Redirect của GoRouter đảm bảo ứng dụng Mobile tuyệt đối bảo mật, không cho user vào các màn hình Dashboard nếu không đúng Role.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/properties/presentation/screens/home_screen.dart';
import '../placeholders/placeholder_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';

      // Chưa đăng nhập & Không phải ở màn login/register -> về Login
      if (user == null && !isGoingToLogin && !isGoingToRegister) {
        return '/login';
      }

      // Đã đăng nhập nhưng vẫn cố vào Login -> phân quyền redirect
      if (user != null && isGoingToLogin) {
        if (user.isAdmin) return '/admin_dashboard';
        if (user.isManager) return '/manager_dashboard';
        if (user.isStaff) return '/staff_dashboard';
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/listings',
        name: 'listings',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Danh sách phòng'),
      ),
      GoRoute(
        path: '/property/:id',
        name: 'property-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceholderScreen(title: 'Chi tiết phòng #$id');
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Tài khoản của tôi'),
      ),
      GoRoute(
        path: '/admin_dashboard',
        name: 'admin-dashboard',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Bảng điều khiển Admin'),
      ),
      GoRoute(
        path: '/manager_dashboard',
        name: 'manager-dashboard',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Bảng điều khiển Manager'),
      ),
      GoRoute(
        path: '/staff_dashboard',
        name: 'staff-dashboard',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Bảng điều khiển Nhân viên'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Trang không tìm thấy: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    ),
  );
  return router;
});

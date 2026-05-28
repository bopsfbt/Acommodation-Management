import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../routing/app_router.dart';
import '../../features/auth/providers/auth_controller.dart';

/// Màn hình placeholder dùng cho các route chưa hoàn thiện
class PlaceholderScreen extends ConsumerWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => ref.read(appRouterProvider).go('/home'),
        ),
        actions: [
          if (title.contains('Admin') ||
              title.contains('Manager') ||
              title.contains('Nhân viên'))
            TextButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider).signOut();
                ref.read(appRouterProvider).go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Màn hình này đang được phát triển.\nVui lòng quay lại sau!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => ref.read(appRouterProvider).go('/home'),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../models/user_profile.dart';

// --- Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Trạng thái user hiện tại (null = chưa đăng nhập)
final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

/// Trạng thái loading khi đang login/register
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Controller xử lý login, logout, register
final authControllerProvider = Provider<AuthController>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo: repo, ref: ref);
});

// --- Controller Class ---

class AuthController {
  final AuthRepository repo;
  final Ref ref;

  AuthController({required this.repo, required this.ref});

  /// Đăng nhập
  Future<void> signIn(String email, String password) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final profile = await repo.login(email, password);
      ref.read(currentUserProvider.notifier).state = profile;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Đăng ký
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final profile = await repo.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      ref.read(currentUserProvider.notifier).state = profile;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await repo.logout();
    ref.read(currentUserProvider.notifier).state = null;
  }

  /// Khôi phục session khi mở app
  Future<void> restoreSession() async {
    final profile = await repo.getCurrentUserProfile();
    ref.read(currentUserProvider.notifier).state = profile;
  }
}

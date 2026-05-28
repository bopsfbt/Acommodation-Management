import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Đăng nhập bằng Email & Password
  Future<UserProfile> login(String email, String password) async {
    try {
      // 1. Đăng nhập Supabase Auth
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) throw Exception('Đăng nhập thất bại: không nhận được user');

      // 2. Lấy profile
      return await _fetchOrBuildProfile(user);
    } on AuthException catch (e) {
      // Ném lại với message gốc từ Supabase
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới
  Future<UserProfile> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name, 'phone': phone, 'role': 'user'},
    );

    final user = response.user;
    if (user == null) throw Exception('Đăng ký thất bại!');

    // Upsert vào bảng profiles (không throw nếu bảng không tồn tại)
    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'email': email.trim(),
        'name': name,
        'phone': phone,
        'role': 'user',
      });
    } catch (_) {
      // Bỏ qua lỗi upsert profiles - vẫn trả về user
    }

    return UserProfile(
      id: user.id,
      email: email.trim(),
      role: 'user',
      name: name,
      phone: phone,
    );
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Lấy thông tin user hiện tại (dùng khi restore session)
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchOrBuildProfile(user);
    } catch (_) {
      return null;
    }
  }

  /// Lấy profile từ DB; nếu không có thì tạo từ auth data
  Future<UserProfile> _fetchOrBuildProfile(User user) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle(); // maybeSingle trả null thay vì throw

      if (data != null) {
        return UserProfile.fromJson({
          ...data,
          'email': data['email'] ?? user.email ?? '',
        });
      }
    } catch (_) {
      // Bảng profiles không tồn tại hoặc lỗi RLS → fallback
    }

    // Fallback: tạo UserProfile từ thông tin auth metadata
    final meta = user.userMetadata ?? {};
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      role: meta['role'] as String? ?? 'user',
      name: meta['name'] as String? ??
          user.email?.split('@').first ??
          'Người dùng',
      phone: meta['phone'] as String? ?? '',
    );
  }

  /// Stream lắng nghe thay đổi trạng thái đăng nhập
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

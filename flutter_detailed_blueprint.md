# Tài Liệu Tổng Thể Xây Dựng Ứng Dụng Flutter (Dart) cho YoungHouseWeb

Tài liệu này cung cấp bản thiết kế kỹ thuật (Technical Blueprint) chi tiết nhất để chuyển đổi dự án `YoungHouseWeb` thành ứng dụng di động bằng **Flutter (Dart)**, tập trung vào kiến trúc thực tế, mô hình dữ liệu, quản lý trạng thái và tích hợp Supabase.

---

## 1. Kiến trúc Hệ thống (System Architecture)

Chúng ta sẽ sử dụng mô hình **Feature-First Architecture** kết hợp với **Riverpod** cho State Management. Kiến trúc này chia nhỏ ứng dụng theo tính năng (Features) thay vì theo loại file, giúp dự án dễ dàng mở rộng khi có nhiều màn hình.

### Các Layer trong mỗi Feature:
1. **Presentation (UI):** Gồm `screens` và `widgets` (Chỉ hiển thị dữ liệu).
2. **Providers (State Management):** Dùng Riverpod để quản lý logic và state (ví dụ: đang load, lỗi, hoặc có data).
3. **Domain (Models):** Các file Dart class mô phỏng cấu trúc bảng Supabase.
4. **Data (Repositories):** Nơi chứa code gọi API trực tiếp tới Supabase.

---

## 2. Cấu trúc Thư mục Chi tiết (Detailed Directory Structure)

Cấu trúc thư mục trong `lib/` sẽ cực kỳ chi tiết như sau:

```text
lib/
├── core/                               # Lõi ứng dụng (Dùng chung)
│   ├── constants/
│   │   ├── app_colors.dart             # Bảng màu (Lấy từ Tailwind config web)
│   │   └── supabase_constants.dart     # URL, Keys của Supabase
│   ├── theme/
│   │   └── app_theme.dart              # Cấu hình ThemeData (Material 3)
│   ├── utils/
│   │   ├── currency_formatter.dart     # Hàm format VNĐ
│   │   └── date_formatter.dart         # Hàm format ngày tháng (Intl)
│   └── routing/
│       └── app_router.dart             # Cấu hình GoRouter
│
├── features/                           # CÁC TÍNH NĂNG CHÍNH
│   │
│   ├── auth/                           # Tính năng Đăng nhập/Đăng ký
│   │   ├── data/
│   │   │   └── auth_repository.dart    # Gọi Supabase.instance.client.auth
│   │   ├── providers/
│   │   │   └── auth_controller.dart    # Riverpod StateNotifier quản lý user state
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           └── auth_text_field.dart
│   │
│   ├── properties/                     # Tính năng Nhà trọ / Tìm kiếm
│   │   ├── models/
│   │   │   └── property_model.dart     # Dart class cho bảng 'phong-tro'
│   │   ├── data/
│   │   │   └── property_repo.dart      # Hàm fetch danh sách phòng, chi tiết phòng
│   │   ├── providers/
│   │   │   └── property_providers.dart # Riverpod FutureProvider fetch data
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── home_screen.dart
│   │       │   ├── explore_screen.dart
│   │       │   └── property_detail_screen.dart
│   │       └── widgets/
│   │           ├── property_card.dart
│   │           └── gallery_slider.dart
│   │
│   ├── bookings/                       # Tính năng Đặt phòng
│   │   ├── models/
│   │   │   └── booking_model.dart      # Dart class cho bảng 'bookings'
│   │   └── ... (cấu trúc tương tự)
│   │
│   └── profile/                        # Tính năng Cá nhân & Dashboard
│       └── ... (cấu trúc tương tự)
│
├── shared/                             # UI dùng chung toàn app
│   ├── primary_button.dart
│   ├── loading_skeleton.dart
│   └── network_image_view.dart
│
├── app.dart                            # Cấu hình gốc MaterialApp
└── main.dart                           # Entry point
```

---

## 3. Mô hình Dữ liệu (Dart Data Models)

Để làm việc mượt mà với Supabase, bạn cần định nghĩa các `Model`. Sử dụng thư viện `freezed` hoặc `json_serializable` để tự động parse JSON, hoặc viết tay nếu mô hình đơn giản.

**Ví dụ: `property_model.dart` (Bảng nhà trọ)**

```dart
class PropertyModel {
  final String id;
  final String title;
  final int price;
  final double area;
  final String address;
  final List<String> images;
  final String? authorId; // ID của chủ nhà

  PropertyModel({
    required this.id,
    required this.title,
    required this.price,
    required this.area,
    required this.address,
    required this.images,
    this.authorId,
  });

  // Chuyển JSON từ Supabase thành Dart Object
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      price: json['price'] as int,
      area: (json['area'] as num).toDouble(),
      address: json['address'] as String,
      // Ép kiểu mảng ảnh
      images: List<String>.from(json['images'] ?? []),
      authorId: json['author_id'] as String?,
    );
  }
}
```

---

## 4. Giao tiếp Backend (Supabase Repositories)

Mọi thao tác gọi dữ liệu (CRUD) sẽ được đưa vào các Repository.

**Ví dụ: `property_repo.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/property_model.dart';

class PropertyRepository {
  final _supabase = Supabase.instance.client;

  // Lấy danh sách phòng trọ mới nhất
  Future<List<PropertyModel>> getRecentProperties() async {
    try {
      final response = await _supabase
          .from('phong-tro') // Tên bảng
          .select()
          .order('created_at', ascending: false)
          .limit(10);
          
      return (response as List)
          .map((item) => PropertyModel.fromJson(item))
          .toList();
    } catch (e) {
      throw Exception('Lỗi khi tải phòng trọ: $e');
    }
  }
}
```

---

## 5. Quản lý Trạng thái (State Management với Riverpod)

Riverpod kết nối Repository (Data) với UI (Screen). Nó tự động xử lý trạng thái Loading, Error và Success.

**Ví dụ: `property_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/property_repo.dart';
import '../models/property_model.dart';

// Provider cung cấp instance của Repository
final propertyRepoProvider = Provider((ref) => PropertyRepository());

// FutureProvider tự động fetch dữ liệu và quản lý trạng thái
final recentPropertiesProvider = FutureProvider<List<PropertyModel>>((ref) async {
  final repo = ref.watch(propertyRepoProvider);
  return repo.getRecentProperties();
});
```

---

## 6. Xây dựng UI (Presentation)

Màn hình UI chỉ cần "lắng nghe" (watch) Riverpod Provider để vẽ giao diện.

**Ví dụ: `home_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_providers.dart';
import '../widgets/property_card.dart'; // Custom Widget của bạn

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theo dõi state của danh sách phòng trọ
    final propertiesAsync = ref.watch(recentPropertiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phòng trọ Hòa Lạc')),
      body: propertiesAsync.when(
        // Trạng thái Data: Hiển thị danh sách
        data: (properties) => ListView.builder(
          itemCount: properties.length,
          itemBuilder: (context, index) {
            final property = properties[index];
            return PropertyCard(property: property);
          },
        ),
        // Trạng thái Loading: Hiển thị vòng xoay hoặc Skeleton
        loading: () => const Center(child: CircularProgressIndicator()),
        // Trạng thái Lỗi
        error: (error, stack) => Center(child: Text('Đã có lỗi: $error')),
      ),
    );
  }
}
```

---

## 7. Các Gói Thư Viện Cụ Thể Cần Cài Trong `pubspec.yaml`

Chạy các lệnh sau trong terminal để cài đặt chuẩn xác:

```bash
# Core
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add go_router

# UI & Utilities
flutter pub add google_fonts
flutter pub add cached_network_image
flutter pub add flutter_svg
flutter pub add intl
flutter pub add url_launcher
flutter pub add shimmer # Hiệu ứng loading cao cấp

# Tùy chọn (Nếu muốn dùng code generation cho JSON - Khuyên dùng cho dự án lớn)
flutter pub add freeezed_annotation
flutter pub add json_annotation
flutter pub add dev:build_runner
flutter pub add dev:freezed
flutter pub add dev:json_serializable
```

---

## 8. Hướng triển khai thực tế

Để không bị ngợp, bạn nên code theo trình tự sau:
1. **Tuần 1:** Setup cấu trúc thư mục, cấu hình Supabase SDK `main.dart`, cấu hình Theme và Router.
2. **Tuần 2:** Xây dựng luồng Auth (Login/Register/Logout) sử dụng `supabase_flutter` auth module.
3. **Tuần 3:** Định nghĩa Data Models và Repositories cho bảng `phong-tro`. Code màn hình Home và hiển thị danh sách phòng.
4. **Tuần 4:** Code màn hình Chi tiết phòng trọ (Property Detail), làm tính năng lọc phòng (Explore/Filter).
5. **Tuần 5:** Làm tính năng Đặt phòng (Bookings) và Quản lý hồ sơ cá nhân. Tích hợp `url_launcher` gọi điện, Zalo.

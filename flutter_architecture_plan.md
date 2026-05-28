# Kế hoạch Xây dựng Ứng dụng Mobile (Flutter) từ Dự án Web

Dựa trên cấu trúc dự án web hiện tại (Next.js + Supabase), dưới đây là tài liệu chi tiết (Blueprint) để bạn phát triển ứng dụng di động cho cả iOS và Android bằng **Flutter** và **Dart**.

---

## 1. Công nghệ & Thư viện khuyên dùng (Tech Stack)

Để đồng bộ với backend hiện tại và đảm bảo hiệu suất tốt nhất, bạn nên sử dụng các package sau trong `pubspec.yaml`:

*   **Backend & Auth:** `supabase_flutter` (Kết nối trực tiếp tới cơ sở dữ liệu và xác thực của Supabase hiện tại).
*   **State Management:** `flutter_riverpod` (Quản lý trạng thái an toàn, dễ scale) hoặc `flutter_bloc`.
*   **Routing:** `go_router` (Quản lý điều hướng mượt mà, hỗ trợ deep-link tốt).
*   **UI & Design:**
    *   `google_fonts`: Sử dụng font chữ hiện đại (vd: Inter, Roboto).
    *   `cached_network_image`: Load và cache hình ảnh nhà trọ, avatar hiệu quả.
    *   `flutter_svg`: Hỗ trợ render các icon/logo SVG.
    *   `carousel_slider`: Hỗ trợ hiển thị slider ảnh nhà trọ (Gallery Slider).
*   **Tiện ích (Utils):**
    *   `shared_preferences`: Lưu trữ cấu hình local (theme, ngôn ngữ, intro screen).
    *   `intl`: Format tiền tệ (VNĐ), ngày tháng.
    *   `url_launcher`: Mở trình duyệt, gọi điện, nhắn tin Zalo (giống tính năng web).

---

## 2. Kiến trúc Codebase (Project Structure)

Nên áp dụng kiến trúc **Feature-driven** kết hợp **Clean Architecture rút gọn** để dễ bảo trì. Cấu trúc thư mục trong `lib/` sẽ như sau:

```text
lib/
├── core/                       # Chứa các thành phần cốt lõi dùng chung toàn app
│   ├── constants/              # App colors, sizes, strings, api_endpoints
│   ├── theme/                  # AppTheme, text styles
│   ├── utils/                  # Formatters, helpers (format tiền, ngày tháng)
│   └── router/                 # Cấu hình go_router
├── features/                   # Chứa các chức năng chính của app
│   ├── auth/                   # Đăng nhập, đăng ký, quên mật khẩu
│   │   ├── data/               # Repositories (Gọi Supabase API)
│   │   ├── models/             # Data classes (User, Session)
│   │   ├── providers/          # Riverpod state/controllers
│   │   └── presentation/       # UI (Screens & Widgets)
│   ├── properties/             # Danh sách phòng trọ, chi tiết phòng trọ
│   ├── bookings/               # Chức năng đặt phòng, lịch sử đặt
│   └── manager/                # Quản lý (Admin): Doanh thu, đăng bài, quản lý khách
├── shared/                     # UI components dùng chung (Buttons, TextFields, Cards)
│   └── widgets/
├── app.dart                    # Widget gốc (MaterialApp cấu hình theme, router)
└── main.dart                   # Entry point (Khởi tạo Supabase, chạy app)
```

---

## 3. Bản đồ UI/UX (Screens Navigation)

Ứng dụng sẽ bao gồm các luồng (flows) màn hình chính sau:

### 3.1. Luồng Xác thực (Auth Flow)
*   **Splash Screen:** Màn hình chờ khởi tạo app, kiểm tra session đăng nhập.
*   **Login / Register Screen:** Giao diện đăng nhập/đăng ký (Tích hợp Supabase Auth - Email/Password hoặc Google/Apple).

### 3.2. Luồng Người dùng cơ bản (Main Flow) - Bottom Navigation Bar
Gồm 4 tab chính:
1.  **Home (Trang chủ):**
    *   Thanh tìm kiếm nhanh.
    *   Danh sách các phòng trọ/nhà nổi bật (Featured).
    *   Danh mục khu vực (Khu vực Hòa Lạc,...).
2.  **Explore (Khám phá / Lọc):**
    *   Bản đồ hoặc danh sách đầy đủ.
    *   Bộ lọc chuyên sâu: Giá, diện tích, tiện ích.
3.  **My Bookings (Lịch sử đặt phòng):**
    *   Danh sách các phòng đang chờ xác nhận, đã duyệt, đã hủy.
4.  **Profile (Cá nhân):**
    *   Hiển thị thông tin user.
    *   Nút chuyển sang giao diện quản lý (Dành cho Admin/Chủ nhà).
    *   Đăng xuất, Cài đặt ứng dụng.

### 3.3. Luồng Quản lý (Manager/Admin Flow)
*   **Dashboard:** Tổng quan thống kê (giống giao diện web hiện tại).
*   **Quản lý Phòng trọ:** Thêm, sửa, xóa, ẩn bài đăng.
*   **Quản lý Đặt phòng (Bookings):** Duyệt/Hủy yêu cầu đặt phòng của khách.
*   **Doanh thu (Revenue):** Biểu đồ doanh thu (Có thể dùng thư viện `fl_chart`).

---

## 4. Kế hoạch Triển khai (Implementation Plan)

### Bước 1: Khởi tạo & Cấu hình môi trường
1.  Tạo project: `flutter create young_house_app`
2.  Cài đặt các package cần thiết trong `pubspec.yaml`.
3.  Tạo file `.env` (hoặc cấu hình trong mã nguồn) chứa **Supabase URL** và **Anon Key**.

### Bước 2: Tích hợp Supabase
Tại file `main.dart`, cấu hình khởi tạo Supabase để kết nối trực tiếp với database hiện tại:

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Thay thế bằng URL và Key dự án của bạn
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const ProviderScope(child: MyApp())); // Nếu dùng Riverpod
}
```

### Bước 3: Xây dựng Core & Shared UI
*   Xây dựng hệ thống màu sắc, typography (cố gắng match với giao diện web đang dùng TailwindCSS).
*   Tạo các Custom Widgets dùng nhiều: `CustomButton`, `CustomTextField`, `ListingCard` (Card hiển thị thông tin nhà trọ).

### Bước 4: Chức năng Authentication
*   Sử dụng `Supabase.instance.client.auth` để làm tính năng Sign in / Sign out.
*   Xử lý RLS (Row-level Security) cho đúng quyền user như đã xử lý bên web.

### Bước 5: Tích hợp tính năng cốt lõi (Properties & Bookings)
*   Tạo file Repository gọi dữ liệu từ bảng `phong-tro`, `bookings`, `profiles` trong Supabase.
*   Ví dụ truy vấn lấy danh sách phòng trọ:
```dart
Future<List<Map<String, dynamic>>> getProperties() async {
  final response = await Supabase.instance.client
      .from('properties') // Thay bằng tên bảng chính xác
      .select('*, profiles(contact_zalo, phone)') // Join data nếu cần
      .order('created_at', ascending: false);
  return response;
}
```

### Bước 6: Xử lý Hình ảnh & Slider
*   Dùng `CachedNetworkImage` để hiển thị ảnh cover và gallery phòng trọ.
*   Lưu ý: Đảm bảo sử dụng `BoxFit.cover` kết hợp tỉ lệ phù hợp (Aspect Ratio) để không bị méo ảnh giống lỗi đã từng fix trên web.

### Bước 7: Luồng Liên hệ & Booking
*   Trong màn hình Chi tiết phòng trọ, thêm nút chức năng: "Đặt phòng" (Booking API) và "Liên hệ Zalo/Gọi điện" (Sử dụng `url_launcher` để mở app mở trình duyệt ngoài thay vì dùng iFrame trực tiếp).

---

## 5. Lưu ý quan trọng
1.  **Row-Level Security (RLS):** Database Supabase của bạn đang cấu hình RLS chặt chẽ. Hãy đảm bảo User trên Mobile app đăng nhập và truyền JWT token đầy đủ lên mỗi request (Supabase Flutter SDK tự động làm điều này nếu bạn dùng module Auth của họ).
2.  **Khả năng Responsive:** Mặc dù là Mobile app, bạn cũng nên thiết kế cho cả màn hình tablet (iPad) để tận dụng hết khả năng của Flutter.
3.  **Xử lý Video TikTok/Iframe:** Nếu ứng dụng web đang có mục "Video Review", trên mobile bạn nên tích hợp package `webview_flutter` hoặc link ra app TikTok gốc để trải nghiệm xem video được tối ưu nhất.

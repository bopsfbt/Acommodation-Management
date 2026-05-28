# Bản Đồ Chuyển Đổi UI: Từ Next.js (React) sang Flutter

Tài liệu này phân tích chi tiết các thư mục `src/app` và `src/components` của dự án web **YoungHouseWeb** hiện tại và hướng dẫn cách ánh xạ (map) chính xác 1-1 các component React/Tailwind sang các Widget chuẩn của **Flutter (Dart)**.

---

## 1. Ánh xạ Cấu trúc Layout & Routing (Từ `src/app` sang Flutter Routes)

### 1.1. Các Màn Hình Dành Cho Khách (Client/Guest)
Trên Next.js, bạn đang dùng thư mục ngoặc đơn (Ví dụ `(home)`, `(stay-listings)`) để nhóm Route. Trên Flutter, sử dụng `GoRouter` để điều hướng.

| Next.js Route (`src/app/`) | Flutter Screen (`lib/features/.../screens/`) | Vai trò / Widget Chính trên Flutter |
| :--- | :--- | :--- |
| `(home)/page.tsx` | `HomeScreen` | Trang chủ: Gồm thanh tìm kiếm, danh sách `SectionGridFeaturePlaces`. Cấu trúc: `CustomScrollView` với các `SliverToBoxAdapter`. |
| `(stay-listings)/phong-tro` | `StayListingsScreen` | Danh sách phòng: Dùng `ListView.builder` hoặc `GridView.builder` để render các `StayCard`. |
| `(listing-detail)/*` | `ListingDetailScreen` | Chi tiết phòng: Dùng `CustomScrollView`, `SliverAppBar` (chứa `GallerySlider`), và `SliverList` cho thông tin mô tả, tiện ích. |
| `login` / `signup` | `LoginScreen` / `SignupScreen`| Luồng Auth: Dùng `Scaffold`, `TextFormField`, `FilledButton`. Kết nối Supabase Auth. |
| `checkout` / `pay-done` | `CheckoutScreen` / `PaymentSuccess`| Màn hình thanh toán: Dùng `Stepper` hoặc `Column` các thẻ thông tin. |
| `wishlist` | `WishlistScreen` | Danh sách yêu thích: Dùng `ListView.builder` hiển thị phòng đã lưu. |
| `video-review` | `VideoReviewScreen` | Dùng thư viện `video_player` hoặc `youtube_player_flutter` (nếu có nhúng video ngoài). |
| `compare` | `CompareScreen` | So sánh phòng: Dùng `DataTable` hoặc `Row` cuộn ngang. |

### 1.2. Các Màn Hình Quản Trị (Dashboards)
Bạn có rất nhiều Role: `admin`, `manager`, `operator`, `tenant`, `author`, `staff`, `ctv`.
Trên Mobile app, thay vì làm nhiều tab rời rạc, hãy gom vào **Dashboard Drawer (Menu trượt)** hoặc **Bottom Navigation**, kiểm tra Role từ JWT Token (Supabase RLS) để quyết định hiển thị gì.

---

## 2. Ánh xạ Các Components UI Cốt Lõi (Từ `src/components` sang Flutter Widgets)

Đây là cách bạn build lại các File React Components sang Flutter Widgets.

### 2.1. Thẻ Hiển Thị (Cards)
| Next.js Component | Tên Flutter Widget Đề Xuất | Cách Build Bằng Flutter |
| :--- | :--- | :--- |
| `StayCard.tsx` / `StayCard2.tsx` / `StayCardH.tsx` | `StayCardWidget` | Bọc ngoài bằng `Card` hoặc `Container` + `BoxDecoration(borderRadius, boxShadow)`. Dùng `Column` chia làm 2 phần: Ảnh (trên) và Text (dưới). Dùng `Row` cho giá tiền và nút yêu thích. |
| `CardCategory1.tsx` -> 6 | `CategoryCardWidget` | Dùng `InkWell` (tạo hiệu ứng click) bọc ngoài `Container`. Ảnh nền, chữ nổi lên trên dùng `Stack`. |
| `CardAuthorBox.tsx` | `AuthorBoxWidget` | Dùng `ListTile` hoặc `Row` gồm `CircleAvatar` (Avatar chủ nhà) và `Column` (Tên, Số ĐT). |

### 2.2. Các Thành Phần Tương Tác (Inputs & Buttons)
| Next.js Component | Tên Flutter Widget Đề Xuất | Cách Build Bằng Flutter |
| :--- | :--- | :--- |
| `LocationSearchInput.tsx` | `LocationSearchWidget` | `TextFormField` + thư viện `flutter_typeahead` để xổ ra danh sách gợi ý. |
| `ModalSelectDate.tsx` | `DateSelectionSheet` | Dùng `showDateRangePicker` mặc định của Flutter (cực kỳ đẹp và mượt) hoặc thư viện `syncfusion_flutter_datepicker`. |
| `ModalSelectGuests.tsx` | `GuestSelectionSheet` | Dùng `showModalBottomSheet`. Bên trong chứa danh sách các `Row` gồm Tên loại khách (Người lớn/Trẻ em) và Nút Tăng/Giảm (`IconButton`). |
| `BtnLikeIcon.tsx` / `LikeSaveBtns.tsx` | `FavoriteButtonWidget` | Dùng `IconButton` với `Icon(Icons.favorite, color: isLiked ? Colors.red : Colors.grey)`. Kèm Riverpod để quản lý state nhấn/nhả. |

### 2.3. Các Section Lớn (Trang Chủ)
| Next.js Component | Tên Flutter Widget Đề Xuất | Cách Build Bằng Flutter |
| :--- | :--- | :--- |
| `SectionGridFeaturePlaces.tsx` | `FeaturedPlacesSection` | Dùng `GridView.builder` với `SliverGridDelegateWithFixedCrossAxisCount` (nếu cần chia cột) hoặc `ListView.builder` cuộn ngang (`scrollDirection: Axis.horizontal`). |
| `GallerySlider.tsx` | `GallerySliderWidget` | Dùng `PageView.builder` kết hợp với `SmoothPageIndicator` (dấu chấm tròn bên dưới). Ảnh fetch bằng `CachedNetworkImage`. |
| `BookingForm.tsx` | `BookingBottomSheet` | Dùng `BottomAppBar` cố định dưới màn hình có nút "Đặt phòng". Bấm vào hiện Bottom Sheet chứa `Form`. |
| `StartRating.tsx` / `FiveStartIconForRate` | `RatingWidget` | Dùng `Row` chứa List.generate các `Icon(Icons.star, color: Colors.amber)`. Hoặc thư viện `flutter_rating_bar`. |
| `ZaloWidget.tsx` | `ZaloContactWidget` | Dùng `FloatingActionButton` hoặc nút trong chi tiết phòng. Khi ấn gọi package `url_launcher` với url: `https://zalo.me/{phone_number}`. |

---

## 3. Kiến Trúc State & Form

Trong các Form như `AddTenantModal.tsx` hay `FeedbackForm.tsx`:
*   **Web (React):** Bạn dùng `useState` hoặc `react-hook-form`.
*   **Flutter:** Sử dụng `GlobalKey<FormState>` kết hợp với các `TextEditingController`. Nếu Form phức tạp, dùng **Riverpod** để lưu trữ trạng thái của từng Input nhằm tự động validate.

---

## 4. Xử Lý Hình Ảnh (Rất Quan Trọng)

Trên web bạn có file `OptimizedImage.tsx` và `SupabaseImage.tsx` để hiển thị ảnh từ Storage và tránh méo ảnh.
Trên Flutter, hãy tạo một custom widget `AppNetworkImage` như sau:

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;

  const AppNetworkImage({super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit, // Cực kỳ quan trọng để ảnh không bị méo (Tương đương object-fit: cover trên Tailwind)
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
```

---

## 5. Kết luận & Lời Khuyên Giai Đoạn Build UI

1. **Bắt đầu từ Atoms (Nhỏ nhất):** Hãy code các Widget nhỏ trước: `BtnLikeIcon`, `StartRating`, `AppNetworkImage`.
2. **Lên Molecules (Thẻ Card):** Sau đó code `StayCard`, `CardCategory`.
3. **Lên Organisms (Sections):** Code `GallerySlider`, `SectionGridFeaturePlaces`.
4. **Lên Pages (Màn hình):** Lắp ráp chúng lại vào `HomeScreen` hay `StayListingsScreen` thông qua `Scaffold` và `CustomScrollView`.
5. Luôn so sánh giao diện với bản Web Tailwind để chỉnh `padding`, `margin`, `borderRadius` cho tương đồng nhất.

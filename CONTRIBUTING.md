# Hướng dẫn đóng góp (CONTRIBUTING)

Đồ án **App đặt món căn tin** (Flutter + Firebase), làm nhóm 2 người.
File này mô tả cách làm việc chung để code không đè lên nhau và `develop` luôn chạy được.

## 1. Nguyên tắc

- Nhánh `develop` là nhánh chính, **có bảo vệ**: không push thẳng, mọi thay đổi đi qua Pull Request (PR).
- Mỗi việc = một Issue = một nhánh = một PR. Nhánh nhỏ, PR nhỏ thì dễ xem và ít xung đột.
- Việc được giao qua GitHub Issues + Projects. Nhận việc nào thì gán tên mình vào Issue đó.
- Được dùng AI hỗ trợ, nhưng **phải giải thích được code mình nộp** (môn học yêu cầu).

## 2. Quy trình cho mỗi việc

1. **Tạo nhánh từ `develop` mới nhất** (làm TRƯỚC khi sửa file):
   ```bash
   git checkout develop
   git pull
   flutter pub get
   git checkout -b feature/ten-viec
   ```
2. **Code** trong phạm vi Issue. Vướng thì hỏi ngay trong Issue.
3. **Kiểm tra** (xem mục 5).
4. **Commit và push**:
   ```bash
   git status
   git add <từng file>
   git commit -m "feat: mô tả ngắn"
   git push -u origin feature/ten-viec
   ```
5. **Mở PR** vào `develop`, điền đủ mẫu mô tả (GitHub tự điền sẵn khung).
6. **Người còn lại xem PR**, chạy `flutter test` trên nhánh đó rồi mới merge.
7. **Dọn nhánh** sau khi PR đã merge:
   ```bash
   git checkout develop
   git pull
   flutter pub get
   git branch -d feature/ten-viec
   git remote prune origin
   ```
   Chỉ xóa nhánh trên GitHub **sau khi** PR đã merge.

## 3. Đặt tên

**Nhánh:** `<loại>/<tên-ngắn-gạch-ngang>`

| Loại        | Dùng cho                        | Ví dụ                       |
| ----------- | ------------------------------- | --------------------------- |
| `feature/`  | Tính năng mới                   | `feature/app-theme`         |
| `fix/`      | Sửa lỗi                         | `fix/restore-logout-button` |
| `refactor/` | Đổi cấu trúc, không đổi hành vi | `refactor/order-id-string`  |
| `docs/`     | Tài liệu                        | `docs/contributing`         |
| `chore/`    | Dọn dẹp, cấu hình               | `chore/cleanup`             |

**Commit:** `<loại>: mô tả ngắn` (feat, fix, refactor, docs, chore, test), ví dụ `feat: add shared app theme`.

## 4. Quy ước code

- **Kiến trúc:** MVVM + Repository, quản lý trạng thái bằng Provider (`ChangeNotifier`).
  Màn hình chỉ hiển thị; logic nằm ở ViewModel; dữ liệu nằm ở Repository.
- **Tham số khởi tạo** dùng private named parameters:
  `required this._orderRepository` (gọi bằng `orderRepository:`).
  Riêng `AuthViewModel` và `MenuViewmodel` nhận tham số vị trí.
- **Trùng tên `Order`:** `cloud_firestore` cũng xuất ra tên `Order`, nên khi import phải viết
  `import 'package:cloud_firestore/cloud_firestore.dart' hide Order;` (hoặc `show ...`).
- **Giao diện:**
  - Màu và kiểu chữ lấy từ theme (`Theme.of(context).colorScheme`, `context.appColors.success`), không viết `Colors.red/green/grey`.
  - Bọc nội dung màn hình trong `ResponsiveCenter` (`lib/core/widgets/`).
  - Thử ở nhiều kích thước: điện thoại dọc/ngang, tablet, Chrome rộng.
- **Dữ liệu và bảo mật:**
  - Ghi Firestore dùng transaction (xem `FirestoreOrderRepository`).
  - Quy tắc chuyển trạng thái đơn nằm ở **hai nơi phải khớp nhau**: `canChangeTo` (trong app) và `validTransition` (trong `firestore.rules`).
  - File `firestore.rules` là nguồn chính thức; áp dụng bằng cách dán vào Firebase Console → Publish.
- **Sửa file có sẵn:** phân biệt rõ "thêm dòng mới" và "thay dòng cũ", đừng làm mất dòng `return`.

## 5. Kiểm tra trước khi mở PR

```bash
flutter test
flutter analyze
```

Cả hai phải sạch. Sau đó thử tay:

- Máy ảo Android (sinh viên) và Chrome (nhân viên), mở **hai terminal**:
  ```bash
  flutter run -d emulator-5554
  flutter run -d chrome
  ```
- Chạy `flutter run -d <id>` trực tiếp trong terminal, không chọn thiết bị bằng menu VS Code (từng gây xung đột cổng).
- Đừng mở hai tab Chrome cùng một app (cache offline của web chỉ hỗ trợ một tab).
- Test dùng Mock; Firebase thật không chạy trong `flutter test`.
- `testWidgets` có `Future.delayed` thật thì bọc trong `tester.runAsync`; widget có stream thì cần `tester.pump()`.

## 6. Mô tả PR

Gồm 5 mục: **Mục đích / Đã làm / Quyết định thiết kế / Cách kiểm tra / Giới hạn hoặc việc sau**.
Mục "Giới hạn" của các PR là tư liệu cho phần hạn chế trong báo cáo.

## 7. Lỗi hay gặp

| Sự cố                                                                                                                                | Cách xử lý                                                                                              |
| ------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Hàng loạt lỗi `undefined_class` sau khi pull                                                                                         | Quên `flutter pub get`                                                                                  |
| `git pull` báo vướng 3 file tự sinh (`GeneratedPluginRegistrant.swift`, `generated_plugin_registrant.cc`, `generated_plugins.cmake`) | `git checkout -- <file>` rồi pull lại                                                                   |
| 3 file tự sinh lẫn vào PR                                                                                                            | Đừng `git add .`; add từng file                                                                         |
| Lỡ commit nhầm trên `develop`                                                                                                        | Tạo nhánh tại chỗ (`git checkout -b feature/...`), push nhánh đó, rồi trả `develop` về `origin/develop` |
| Xóa nhánh GitHub trước khi merge                                                                                                     | `git push -u origin <nhánh>` rồi Reopen PR                                                              |
| Máy ảo mất kết nối adb                                                                                                               | `adb kill-server` rồi `adb start-server`; Cold Boot máy ảo; đóng VMware khi chạy emulator               |
| `flutter_local_notifications` đòi desugaring                                                                                         | Bật `isCoreLibraryDesugaringEnabled` trong `android/app/build.gradle.kts`                               |
| Plugin không build trên Windows                                                                                                      | Bật Developer Mode của Windows                                                                          |

> Nhánh: `feature/firebase-setup` (đã merge vào `develop`). Cập nhật: 03/10/2026.

## Có gì mới?

- Đã thêm gói `firebase_core` và khởi tạo Firebase trong `lib/main.dart`.
- Có 2 file cấu hình mới (không sửa tay):
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
- Chưa có tính năng nào dùng Firebase. Đây chỉ là nền cho đăng nhập và đơn hàng ở các nhánh sau.

## Việc bạn cần làm sau khi pull

1. Cập nhật code:

   ```bash
   git checkout develop
   git pull
   flutter pub get
   ```

   (Quên `flutter pub get` sẽ ra hàng loạt lỗi `undefined_class`.)

2. **Windows: bật Developer Mode** (chỉ làm 1 lần). Nếu không sẽ gặp lỗi `Building with plugins requires symlink support`.

   ```powershell
   start ms-settings:developers
   ```

   Bật công tắc Developer Mode, rồi đóng và mở lại VS Code.

3. Chạy app trên máy ảo Android:

   ```bash
   flutter run -d emulator-5554
   ```

4. Kiểm tra: trong terminal phải có dòng

   ```
   Firebase OK: canteen-app-xxxxx
   ```

   Thấy dòng này là cấu hình chạy được trên máy bạn.

5. Chạy `flutter test` và `flutter analyze`, cả hai phải sạch.

## Lỗi hay gặp

| Lỗi                                                       | Cách xử lý                                     |
| --------------------------------------------------------- | ---------------------------------------------- |
| `Building with plugins requires symlink support`          | Bật Developer Mode (bước 2)                    |
| `No Firebase App '[DEFAULT]' has been created`            | Chưa pull bản mới, hoặc chưa `flutter pub get` |
| Thiếu `firebase_options.dart` hoặc `google-services.json` | `git pull` lại; nếu vẫn thiếu thì báo Luci     |
| Build Gradle lỗi lạ                                       | `flutter clean` → `flutter pub get` → chạy lại |
| Máy ảo mất kết nối                                        | `adb kill-server` rồi `adb start-server`       |
| Dòng `WARNING: ... Kotlin Gradle Plugin`                  | Bỏ qua, không ảnh hưởng                        |

## Lưu ý

- **Không sửa tay** `firebase_options.dart` và `google-services.json`.
- SQLite (`sqflite`) vẫn không chạy trên Chrome, nên đặt đơn hãy thử trên máy ảo Android.

## Việc cần làm

- Chạy theo các bước trên và báo lại có thấy dòng `Firebase OK` không.
- Nếu gặp lỗi nào chưa có trong bảng, ghi lại lỗi và cách sửa, rồi thêm vào mục "Setup Firebase" của `CONTRIBUTING.md` (nhánh `docs/firebase-setup`).
- Tiếp tục Issue #11 như cũ, việc này không đụng tới Firebase.

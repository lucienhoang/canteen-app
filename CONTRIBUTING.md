# Quy trình làm việc nhóm: Đồ án App đặt món căn tin

Repo: https://github.com/lucienhoang/canteen-app

Mốc chính: khoảng 11/10 kiểm tra luồng chính (đặt món → theo dõi đơn), 19/10 đóng băng tính năng, khoảng 25/10 demo.

## 1. Nguyên tắc chung

- Không ai push thẳng lên `main` hay `develop`. Mọi thay đổi đều đi qua nhánh riêng và Pull Request (PR).
- `main` là bản ổn định để nộp và demo, `develop` là nơi hai người gộp code, còn mỗi việc làm trên một nhánh riêng (`feature/...`, `fix/...`, `docs/...`).
- Ai làm phần nào thì làm trong thư mục của phần đó (xem mục 6) để hạn chế đụng file của nhau.
- Có gì không hiểu, kẹt quá thì alo luôn. Hỏi sớm rẻ hơn sửa muộn.

## 2. Cài đặt lần đầu (chỉ làm một lần)

```
git config --global user.name "Tên bạn"
git config --global user.email "email-dùng-cho-github"
git clone https://github.com/lucienhoang/canteen-app.git
cd canteen-app
git checkout develop
flutter pub get
```

Nhớ chấp nhận lời mời cộng tác (Collaborator) trong email hoặc phần Notifications trên GitHub trước khi clone.

## 3. Vòng làm việc cho mỗi việc mới

```
git checkout develop
git pull                            # luôn pull trước khi bắt đầu
git checkout -b feature/ten-viec    # ví dụ: feature/menu-screen
# ... viết code ...
flutter test
flutter analyze                     # cả hai đều phải sạch
git add .
git commit -m "feat: mô tả ngắn"
git push -u origin feature/ten-viec
```

Sau đó lên GitHub bấm **Compare & pull request**, chọn đích là `develop`, viết vài dòng mô tả những gì đã làm, rồi nhờ người còn lại review.

## 4. Quy ước đặt tên

**Nhánh:** viết thường, nối bằng gạch ngang.

- `feature/ten-viec` cho tính năng mới
- `fix/ten-loi` cho sửa lỗi
- `docs/ten-tai-lieu` cho tài liệu, báo cáo

**Commit:** bắt đầu bằng loại việc rồi tới mô tả ngắn.

- `feat:` tính năng mới, ví dụ `feat: add menu list screen`
- `fix:` sửa lỗi, ví dụ `fix: wrong cart total`
- `docs:` tài liệu, báo cáo
- `test:` thêm hoặc sửa test
- `chore:` việc lặt vặt, cấu hình

**File Dart:** viết thường, nối bằng gạch dưới, ví dụ `menu_screen.dart`, `cart_viewmodel.dart`.

**Class:** viết hoa chữ đầu mỗi từ, ví dụ `MenuScreen`, `CartViewModel`.

## 5. Quy ước Pull Request và review

- Mỗi PR chỉ làm **một việc**, nhỏ và gọn (một màn hình hoặc một tính năng). PR nhỏ thì dễ review và ít xung đột.
- Trước khi tạo PR: `flutter test` và `flutter analyze` phải sạch, và app phải chạy được.
- Người còn lại review trong vòng 1 ngày. Có chỗ cần sửa thì comment ngay trên PR, sửa xong push thêm lên cùng nhánh, PR tự cập nhật.
- Review xong thì merge vào `develop`, rồi bấm **Delete branch** trên GitHub để xóa nhánh trên mạng.
- Sau khi merge, dọn dẹp trên máy của mình:

```
git checkout develop
git pull                             # lấy bản develop đã gộp code
git branch -d feature/ten-viec       # xóa nhánh đã làm xong ở máy
git fetch --prune                    # xóa các nhánh đã bị xóa trên GitHub khỏi danh sách
```

Dùng `-d` (chữ thường) thì Git chỉ xóa khi nhánh đã được gộp, nên không lo xóa nhầm việc chưa xong. Nếu Git báo nhánh "chưa được gộp" dù bạn đã merge PR xong, hỏi nhau trước khi dùng `-D`.

## 6. Cấu trúc thư mục và phân việc

```
lib/
  core/          dùng chung: theme, hằng số
  data/          models, repositories (dữ liệu)
  features/
    menu/        màn hình menu, chi tiết món
    cart/        giỏ hàng, đặt đơn
    orders/      theo dõi đơn, lịch sử đơn
    staff/       màn hình nhân viên căn tin
```

Mỗi tính năng trong `features/` gồm màn hình (View) và ViewModel riêng. Các file dùng chung (`core/`, `main.dart`, `pubspec.yaml`) chỉ một người sửa, người kia cần gì thì nhắn để tránh xung đột.

## 7. Quy ước code

- Kiến trúc MVVM: View chỉ lo hiển thị, logic nằm trong ViewModel, việc lấy/lưu dữ liệu nằm trong Repository.
- Quản lý trạng thái bằng Provider.
- Không để logic tính toán trong widget. Đặt vào ViewModel để dễ test.
- Có comment ngắn ở đoạn logic khó hiểu, vì cả hai đều phải giải thích được code của mình khi bảo vệ.

## 8. Cách phối hợp

- Việc được chia bằng **GitHub Issues** và bảng **Projects**. Mỗi việc là một issue có người phụ trách, chuyển cột theo tiến độ: To do → Doing → Review → Done.
- Họp nhanh 2-3 lần một tuần (10-15 phút, gọi hoặc nhắn) để báo tiến độ và gỡ vướng.
- Nếu gặp xung đột khi gộp code (conflict), đừng tự xóa lung tung, nhắn cho nhau xem cùng.

## 9. Việc cần làm ngay

1. Chấp nhận lời mời vào repo và cài môi trường Flutter.
2. Clone repo, chạy thử `flutter test` để chắc máy ổn.
3. Nhận việc đầu tiên trong mục Issues.

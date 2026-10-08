import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/user_role.dart';
import 'package:canteen_app/data/repositories/auth_repository.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  test('đăng nhập sinh viên đúng mật khẩu -> role student', () async {
    final user = await repo.signIn(loginId: '2110001', password: '123456');
    expect(user.role, UserRole.student);
    expect(user.name, 'Nguyễn Văn A');
  });

  test('đăng nhập nhân viên -> role staff', () async {
    final user = await repo.signIn(loginId: 'NV01', password: 'staff123');
    expect(user.role, UserRole.staff);
  });

  test('mã số không phân biệt hoa thường và bỏ khoảng trắng', () async {
    final user = await repo.signIn(loginId: '  nv01 ', password: 'staff123');
    expect(user.isStaff, true);
  });

  test('sai mật khẩu -> ném AuthException', () async {
    expect(
      repo.signIn(loginId: '2110001', password: 'sai'),
      throwsA(isA<AuthException>()),
    );
  });

  test('mã số không tồn tại -> ném AuthException cùng thông báo', () async {
    expect(
      repo.signIn(loginId: 'khong-co', password: '123456'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Sai mã số hoặc mật khẩu',
        ),
      ),
    );
  });

  test(
    'getCurrentUser: null trước khi đăng nhập, có user sau khi đăng nhập',
    () async {
      expect(await repo.getCurrentUser(), isNull);

      await repo.signIn(loginId: '2110001', password: '123456');
      final current = await repo.getCurrentUser();
      expect(current?.mssv, '2110001');
    },
  );

  test('signOut xóa người đang đăng nhập', () async {
    await repo.signIn(loginId: '2110001', password: '123456');
    await repo.signOut();
    expect(await repo.getCurrentUser(), isNull);
  });

  test('đăng nhập sai không làm mất phiên đang có', () async {
    await repo.signIn(loginId: '2110001', password: '123456');
    await expectLater(
      repo.signIn(loginId: '2110002', password: 'sai'),
      throwsA(isA<AuthException>()),
    );
    expect((await repo.getCurrentUser())?.mssv, '2110001');
  });
}

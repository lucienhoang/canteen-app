import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/models/app_user.dart';
import 'package:canteen_app/data/models/user_role.dart';

void main() {
  group('UserRole', () {
    test('fromName đọc đúng role hợp lệ', () {
      expect(UserRole.fromName('staff'), UserRole.staff);
      expect(UserRole.fromName('student'), UserRole.student);
    });

    test('fromName: giá trị lạ hoặc null -> student (quyền thấp nhất)', () {
      expect(UserRole.fromName('admin'), UserRole.student);
      expect(UserRole.fromName(null), UserRole.student);
    });
  });

  group('AppUser', () {
    test('toMap rồi fromMap trả lại đúng dữ liệu', () {
      const user = AppUser(
        id: 'u1',
        name: 'Nguyễn Văn A',
        mssv: '2110001',
        role: UserRole.staff,
      );

      final restored = AppUser.fromMap('u1', user.toMap());

      expect(restored.id, 'u1');
      expect(restored.name, 'Nguyễn Văn A');
      expect(restored.mssv, '2110001');
      expect(restored.role, UserRole.staff);
    });

    test('toMap không chứa id', () {
      const user = AppUser(
        id: 'u1',
        name: 'A',
        mssv: '1',
        role: UserRole.student,
      );
      expect(user.toMap().containsKey('id'), false);
    });

    test('isStaff đúng theo role', () {
      const staff = AppUser(
        id: '1',
        name: 'A',
        mssv: '1',
        role: UserRole.staff,
      );
      const student = AppUser(
        id: '2',
        name: 'B',
        mssv: '2',
        role: UserRole.student,
      );
      expect(staff.isStaff, true);
      expect(student.isStaff, false);
    });

    test('fromMap thiếu dữ liệu vẫn không văng lỗi, role về student', () {
      final user = AppUser.fromMap('u9', {});
      expect(user.name, '');
      expect(user.role, UserRole.student);
    });
  });
}

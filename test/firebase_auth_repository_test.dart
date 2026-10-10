import 'package:flutter_test/flutter_test.dart';
import 'package:canteen_app/data/repositories/firebase_auth_repository.dart';

/// Firebase thật không chạy được trong `flutter test`, nên ở đây chỉ test
/// phần logic thuần (ghép email, đổi mã lỗi thành thông báo).
/// Phần đăng nhập thật được kiểm chứng bằng test tay trên máy ảo.
void main() {
  group('toEmail', () {
    test('ghép đuôi @canteen.local', () {
      expect(
        FirebaseAuthRepository.toEmail('2110001'),
        '2110001@canteen.local',
      );
    });

    test('bỏ khoảng trắng hai đầu và về chữ thường', () {
      expect(FirebaseAuthRepository.toEmail('  NV01 '), 'nv01@canteen.local');
    });
  });

  group('messageForCode', () {
    test('các lỗi "sai thông tin" dùng chung một thông báo', () {
      const expected = 'Sai mã số hoặc mật khẩu';
      for (final code in [
        'invalid-credential',
        'invalid-email',
        'user-not-found',
        'wrong-password',
      ]) {
        expect(FirebaseAuthRepository.messageForCode(code), expected);
      }
    });

    test('mất mạng có thông báo riêng', () {
      expect(
        FirebaseAuthRepository.messageForCode('network-request-failed'),
        contains('kết nối mạng'),
      );
    });

    test('thử quá nhiều lần có thông báo riêng', () {
      expect(
        FirebaseAuthRepository.messageForCode('too-many-requests'),
        contains('quá nhiều lần'),
      );
    });

    test('tài khoản bị khóa có thông báo riêng', () {
      expect(
        FirebaseAuthRepository.messageForCode('user-disabled'),
        contains('bị khóa'),
      );
    });

    test('mã lỗi lạ rơi về thông báo chung', () {
      expect(
        FirebaseAuthRepository.messageForCode('abc-xyz'),
        'Đăng nhập thất bại, thử lại nhé',
      );
    });
  });
}

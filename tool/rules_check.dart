// Công cụ kiểm tra Firestore Security Rules bằng tài khoản thật.
//
// Chạy:  flutter run -d chrome -t tool/rules_check.dart
//
// Công cụ đăng nhập lần lượt: sinh viên 2110001, sinh viên 2110002, nhân viên NV01,
// rồi thử các thao tác được phép và các thao tác bị cấm. Mỗi dòng PASS nghĩa là
// kết quả đúng như mong đợi. Công cụ tạo vài đơn thử (ghi chú "rules-check") và
// cuối cùng tự hủy chúng để không làm rối danh sách của nhân viên.
//
// Đây là file chạy riêng, KHÔNG nằm trong app.
import 'package:canteen_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _RulesCheckApp());
}

class _Result {
  const _Result(this.label, this.ok, this.detail);

  final String label;
  final bool ok;
  final String detail;
}

class _RulesCheckApp extends StatefulWidget {
  const _RulesCheckApp();

  @override
  State<_RulesCheckApp> createState() => _RulesCheckAppState();
}

class _RulesCheckAppState extends State<_RulesCheckApp> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final List<_Result> _results = [];
  bool _finished = false;
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    _runAll();
  }

  // ---------------------------------------------------------------------------
  // Hàm hỗ trợ
  // ---------------------------------------------------------------------------

  Future<String> _signIn(String loginId, String password) async {
    await _auth.signOut();
    final credential = await _auth.signInWithEmailAndPassword(
      email: '${loginId.toLowerCase()}@canteen.local',
      password: password,
    );
    return credential.user!.uid;
  }

  Future<Map<String, String>> _profile(String uid) async {
    final data = (await _db.collection('users').doc(uid).get()).data()!;
    return {'name': data['name'] as String, 'mssv': data['mssv'] as String};
  }

  Map<String, dynamic> _order(
    String uid,
    Map<String, String> profile, {
    Map<String, dynamic> overrides = const {},
  }) {
    return {
      'userId': uid,
      'userName': profile['name'],
      'userMssv': profile['mssv'],
      'status': 'pending',
      'pickupTime': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 30)),
      ),
      'note': 'rules-check',
      'createdAt': Timestamp.now(),
      'items': [
        {
          'menuItemId': 1,
          'menuItemName': 'Món thử',
          'priceAtOrder': 1000,
          'quantity': 1,
        },
      ],
      'totalAmount': 1000,
      ...overrides,
    };
  }

  /// Chạy một thao tác và so với mong đợi (được phép hay bị từ chối).
  Future<void> _check(
    String label,
    bool expectAllowed,
    Future<Object?> Function() action,
  ) async {
    bool? allowed;
    String detail = '';
    try {
      await action();
      allowed = true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        allowed = false;
      } else {
        detail = 'LỖI KHÁC: ${e.code}';
      }
    }

    final ok = allowed != null && allowed == expectAllowed;
    if (allowed != null) {
      detail = allowed ? 'được phép' : 'bị từ chối';
    }
    final line =
        '${ok ? 'PASS' : 'FAIL'}  $label  ->  $detail '
        '(mong đợi: ${expectAllowed ? 'được phép' : 'bị từ chối'})';
    debugPrint(line);
    if (mounted) setState(() => _results.add(_Result(label, ok, detail)));
  }

  // ---------------------------------------------------------------------------
  // Các kiểm tra
  // ---------------------------------------------------------------------------

  Future<void> _runAll() async {
    try {
      final orders = _db.collection('orders');

      // ===== Sinh viên A =====
      final uidA = await _signIn('2110001', '123456');
      final profileA = await _profile(uidA);
      final docA = orders.doc();

      await _check(
        'SV tạo đơn hợp lệ của chính mình',
        true,
        () => docA.set(_order(uidA, profileA)),
      );
      await _check(
        'SV tạo đơn mang userId của người khác',
        false,
        () => orders.doc().set(_order('uid-nguoi-khac', profileA)),
      );
      await _check(
        'SV tạo đơn có trạng thái "ready" (không phải pending)',
        false,
        () => orders.doc().set(
          _order(uidA, profileA, overrides: {'status': 'ready'}),
        ),
      );
      await _check(
        'SV tạo đơn với tên giả (không khớp hồ sơ)',
        false,
        () => orders.doc().set(
          _order(uidA, profileA, overrides: {'userName': 'Tên giả'}),
        ),
      );
      await _check(
        'SV tạo đơn có trường lạ (isPaid)',
        false,
        () => orders.doc().set(
          _order(uidA, profileA, overrides: {'isPaid': true}),
        ),
      );
      await _check(
        'SV tạo đơn không có món nào',
        false,
        () =>
            orders.doc().set(_order(uidA, profileA, overrides: {'items': []})),
      );
      await _check('SV đọc đơn của chính mình', true, () => docA.get());
      await _check(
        'SV liệt kê đơn của mình (where userId)',
        true,
        () => orders.where('userId', isEqualTo: uidA).limit(5).get(),
      );
      await _check(
        'SV liệt kê TẤT CẢ đơn (không lọc)',
        false,
        () => orders.limit(5).get(),
      );
      await _check(
        'SV tự đổi trạng thái đơn của mình',
        false,
        () => docA.update({'status': 'preparing'}),
      );
      await _check('SV xóa đơn của mình', false, () => docA.delete());
      await _check(
        'SV đọc hồ sơ của người khác',
        false,
        () => _db.collection('users').doc('uid-nguoi-khac').get(),
      );
      await _check(
        'SV tự nâng mình thành nhân viên',
        false,
        () => _db.collection('users').doc(uidA).update({'role': 'staff'}),
      );
      await _check(
        'SV đọc collection lạ',
        false,
        () => _db.collection('bi-mat').limit(1).get(),
      );

      // ===== Sinh viên B =====
      final uidB = await _signIn('2110002', '123456');
      final profileB = await _profile(uidB);
      final docB = orders.doc();

      await _check(
        'SV khác tạo đơn hợp lệ của mình',
        true,
        () => docB.set(_order(uidB, profileB)),
      );
      await _check('SV đọc đơn của SV khác', false, () => docA.get());

      // ===== Nhân viên =====
      final uidStaff = await _signIn('NV01', 'staff123');
      final profileStaff = await _profile(uidStaff);
      await _check(
        'NV liệt kê tất cả đơn',
        true,
        () => orders.orderBy('createdAt', descending: true).limit(5).get(),
      );
      await _check('NV đọc đơn của sinh viên', true, () => docA.get());
      await _check(
        'NV chuyển pending -> ready (nhảy bước)',
        false,
        () => docA.update({'status': 'ready'}),
      );
      await _check(
        'NV đổi trạng thái kèm sửa trường khác (userName)',
        false,
        () => docA.update({'status': 'preparing', 'userName': 'Sửa trộm'}),
      );
      await _check(
        'NV chuyển pending -> preparing (hợp lệ)',
        true,
        () => docA.update({'status': 'preparing'}),
      );
      await _check(
        'NV chuyển preparing -> completed (nhảy bước)',
        false,
        () => docA.update({'status': 'completed'}),
      );
      await _check('NV xóa đơn', false, () => docA.delete());
      await _check(
        'NV tạo đơn thay cho sinh viên (userId khác)',
        false,
        () => orders.doc().set(_order(uidA, profileStaff)),
      );

      // Dọn dẹp: hủy các đơn thử để chúng không nằm trong danh sách đang xử lý
      await _check(
        'NV hủy đơn thử A (preparing -> cancelled)',
        true,
        () => docA.update({'status': 'cancelled'}),
      );
      await _check(
        'NV hủy đơn thử B (pending -> cancelled)',
        true,
        () => docB.update({'status': 'cancelled'}),
      );
      await _check(
        'NV sửa đơn đã hủy (cancelled -> pending)',
        false,
        () => docA.update({'status': 'pending'}),
      );

      // ===== Chưa đăng nhập =====
      await _auth.signOut();
      await _check('Chưa đăng nhập: đọc đơn', false, () => docA.get());
      await _check(
        'Chưa đăng nhập: tạo đơn',
        false,
        () => orders.doc().set(_order(uidA, profileA)),
      );
    } catch (e, st) {
      debugPrint('Công cụ gặp lỗi: $e\n$st');
      if (mounted) setState(() => _fatalError = '$e');
    } finally {
      await _auth.signOut();
      if (mounted) setState(() => _finished = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.ok).length;
    final summary = _fatalError != null
        ? 'Công cụ dừng giữa chừng: $_fatalError'
        : _finished
        ? (passed == _results.length
              ? 'Tất cả ${_results.length} kiểm tra đều đạt'
              : 'Có ${_results.length - passed} kiểm tra KHÔNG đạt (trên tổng ${_results.length})')
        : 'Đang chạy... ($passed/${_results.length} đạt)';

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Kiểm tra Firestore Rules')),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Text(
                summary,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final r in _results)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        r.ok ? Icons.check_circle : Icons.cancel,
                        color: r.ok ? Colors.green : Colors.red,
                      ),
                      title: Text(r.label),
                      subtitle: Text(r.detail),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// Cho biết máy đang có kết nối mạng hay không.
///
/// Tách thành lớp trừu tượng vì plugin gọi code native, không chạy được
/// trong unit test. Test dùng bản giả, app thật dùng [PlusConnectivityService].
abstract class ConnectivityService {
  /// Kiểm tra ngay lúc này.
  Future<bool> isOnline();

  /// Phát giá trị mới mỗi khi trạng thái mạng đổi (true = có mạng).
  Stream<bool> get onlineChanges;
}

/// Bản thật, dùng gói `connectivity_plus`.
///
/// Lưu ý: chỉ biết máy có kết nối WiFi/4G hay không, KHÔNG biết kết nối đó
/// có ra được Internet hay không. Trường hợp "có WiFi nhưng treo" do timeout
/// trong repository xử lý.
class PlusConnectivityService implements ConnectivityService {
  PlusConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Plugin trả về một danh sách (máy có thể vừa WiFi vừa 4G).
  /// Có ít nhất một kết nối khác `none` thì coi là có mạng.
  static bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(_hasNetwork).distinct();
}

import 'order_item.dart';
import 'order_status.dart';

/// Lớp đại diện cho một đơn hàng.
///
/// Gồm danh sách [OrderItem] (các món đã đặt), trạng thái đơn([OrderStatus]),
/// và thông tin lấy hàng (giờ hẹn, ghi chú).
class Order {
  /// Mã định danh duy nhất của đơn hàng, dạng chuỗi
  /// (khớp với id document của Firestore ở các nhánh sau).
  /// [null] khi chưa được lưu vào cơ sở dữ liệu.
  final String? id;

  /// Mã người dùng đặt đơn
  final String userId;

  /// Bản sao tên người đặt tại thời điểm đặt đơn.
  /// Cùng tinh thần với "giá tại thời điểm đặt": nhân viên đọc đơn
  /// không cần truy vấn thêm bảng người dùng.
  final String userName;

  /// Bản sao mã số sinh viên của người đặt tại thời điểm đặt đơn.
  final String userMssv;

  /// Danh sách các món trong đơn hàng.
  final List<OrderItem> items;

  /// Trạng thái hiển thị của đơn hàng.
  /// Mặc định là [OrderStatus.pending] khi mới tạo
  final OrderStatus status;

  /// Giờ hẹn lấy món
  final DateTime pickupTime;

  /// Ghi chú của khách (nếu có)
  final String? note;

  /// Thời điểm đơn hàng được tạo
  final DateTime createdAt;

  /// Hàm khởi tạo cố định cho Order.
  const Order({
    this.id,
    required this.userId,
    this.userName = '',
    this.userMssv = '',
    required this.items,
    this.status = OrderStatus.pending,
    required this.pickupTime,
    this.note,
    required this.createdAt,
  });

  /// Tổng tiền cả đơn = cộng dồn [OrderItem.subtotal] của từng món.
  int get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);

  /// Tọa bản sao của [Order], chỉ thay field nào được truyền vào.
  /// Dùng khi cần đỏi trạng thái đơn (VD: pending -> preparing) mà
  /// không sửa trực tiếp object đang được UI theo dõi.
  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userMssv,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? pickupTime,
    String? note,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userMssv: userMssv ?? this.userMssv,
      items: items ?? this.items,
      status: status ?? this.status,
      pickupTime: pickupTime ?? this.pickupTime,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Dùng khi lưu vào bảng orders trong SQLite. items lưu riêng ở bảng
  // order_items nên không có trong map này.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_mssv': userMssv,
      'status': status.name,
      'pickup_time': pickupTime.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // items được truyền riêng vì SQLite lưu orders và order_items ở 2 bảng
  // khác nhau — Repository sẽ query cả 2 bảng rồi ráp lại bằng hàm này.
  factory Order.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      // SQLite trả id dạng số nguyên; đổi sang chuỗi để thống nhất kiểu id.
      id: map['id']?.toString(),
      userId: map['user_id'] as String,
      // Đơn cũ (tạo trước khi có hai cột này) sẽ có tên/MSSV rỗng.
      userName: map['user_name'] as String? ?? '',
      userMssv: map['user_mssv'] as String? ?? '',
      items: items,
      status: OrderStatus.values.byName(map['status'] as String),
      pickupTime: DateTime.parse(map['pickup_time'] as String),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

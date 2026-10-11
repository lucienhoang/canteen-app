/// Lỗi khi thao tác với đơn hàng (mất mạng, hết thời gian, thiếu quyền...).
/// [message] đã là câu tiếng Việt thân thiện, ViewModel có thể hiện thẳng lên giao diện.
class OrderRepositoryException implements Exception {
  const OrderRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'OrderRepositoryException: $message';
}

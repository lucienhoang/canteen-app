import '../models/category.dart';
import '../models/menu_item.dart';

/// Interface quản lý việc truy xuất thực đơn.
/// Định nghĩa các hàm mà bất kỳ nguồn dữ liệu nào (Mock, SQLite, API) cũng phải thực thi.
abstract class MenuRepository {
  /// Lấy danh sách tất cả các danh mục
  Future<List<Category>> getCategories();

  /// Lấy danh sách tất cả các món ăn / thức uống
  Future<List<MenuItem>> getMenuItems();
}

/// Triển khai [MenuRepository] sử dụng dữ liệu giả lập (Mock Data).
/// Phù hợp trong quá trình phát triển giao diện hoặc viết kiểm thử.
class MockMenuRepository implements MenuRepository {
  @override
  Future<List<Category>> getCategories() async {
    // Giả lập thời gian chờ phản hồi từ Server/Database (800 milliseconds)
    await Future.delayed(const Duration(milliseconds: 800));

    // Trả về danh mục giả
    return const [
      Category(id: 1, name: "Cơm"),
      Category(id: 2, name: "Bún/Phở"),
      Category(id: 3, name: "Đồ uống"),
    ];
  }

  @override
  Future<List<MenuItem>> getMenuItems() async {
    // Giả lập thời gian chờ phản hồi từ Server/Database (800 milliseconds)
    await Future.delayed(const Duration(milliseconds: 800));

    // Trả về danh sách món ăn giả
    return const [
      MenuItem(id: 1, categoryId: 1, name: "Cơm gà xối mỡ", price: 35000),
      MenuItem(id: 2, categoryId: 1, name: "Cơm sườn", price: 32000),
      MenuItem(id: 3, categoryId: 2, name: "Phở bò", price: 40000),
      MenuItem(
        id: 4,
        categoryId: 2,
        name: "Bún riêu",
        price: 35000,
        isAvailable: false,
      ),
      MenuItem(id: 5, categoryId: 3, name: "Trà đào", price: 35000),
      MenuItem(id: 6, categoryId: 3, name: "Cà phê sữa", price: 35000),
    ];
  }
}

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../data/models/category.dart';
import '../../data/models/menu_item.dart';
import '../../data/repositories/menu_repository.dart';

/// ViewModel quản lý trạng thái và logic nghiệp vụ cho màn hình Thực đơn (Menu Screen).
/// Sử dụng [ChangeNotifier] để thông báo thay đổi cho tầng UI quan sát.
class MenuViewmodel extends ChangeNotifier {
  /// Hàm khởi tạo nhận vào một [MenuRepository] (Dependency Ịnection).
  /// Giúp ViewModel độc lập với nguồn dữ liệu bên dưới.
  MenuViewmodel(this._repository);

  final MenuRepository _repository;

  // --- Trạng thái nội bộ (Private States) ---
  bool _isLoading = false;
  String? _error;
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  int? _selectedCategoryId; // null nghĩa là đang chọn "Tất cả"

  // --- Getter cung cấp dữ liệu an toàn cho tầng UI ---

  /// Trạng thái đang tải dữ liệu
  bool get isLoading => _isLoading;

  /// Thông báo lỗi (nếu có)
  String? get error => _error;

  /// Danh sách tất cả các danh mục
  List<Category> get categories => _categories;

  /// Id của danh mục hiện đang được chọn
  int? get selectedCategoryId => _selectedCategoryId;

  /// Danh sách món được lọc tự động dựa theo theo danh mục đang chọn.
  /// Nếu [_selectedCategoryId] là null thì trả về toàn bộ danh sách món.
  List<MenuItem> get visibleItems {
    if (_selectedCategoryId == null) return _items;
    return _items.where((i) => i.categoryId == _selectedCategoryId).toList();
  }

  /// Tải danh sách danh mục và món từ Repository.
  /// Xử lý đồng thời trạng thái Loading, Lỗi và Cập nhật giao diện.
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Thông báo UI hiển thị trạng thái Loading
    try {
      _categories = await _repository.getCategories();
      _items = await _repository.getMenuItems();
    } catch (e) {
      _error = "Không tải được menu, thử lại nhé.";
    } finally {
      _isLoading = false;
      notifyListeners(); // Thông báo UI tắt Loading và hiển thị dữ liệu/lỗi
    }
  }

  /// Thay đổi danh mục đang chọn để lọc lại danh sách món ăn.
  /// Truyền vào null nếu muốn chọn tất cả danh mục.
  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners(); // Thông báo UI cập nhật lại danh sách hiển thị
  }
}

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Quản lý kết nối và khởi tạo cơ sở dữ liệu SQLite dùng chung (Singleton Pattern).
/// Tự động khởi tạo bảng [orders] và [order_items] khi ứng dụng chạy lần đầu.
class DatabaseHelper {
  // Hàm khởi tạo riêng tư (Private Constructor)
  DatabaseHelper._internal();

  /// Thể hiện duy nhất của [DatabaseHelper] trong toàn bộ ứng dụng
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  /// Lấy đối tượng [Database] hiện tại.
  /// Tự động khởi tạo kết nối nếu database chưa được mở.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Khởi tạo và kết nối tới file cơ sở dữ liệu SQLite dưới bộ nhớ thiết bị
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'canteen_app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => _createTables(db),
    );
  }

  /// Tạo cấu trúc các bảng cho ứng dụng khi DB được tạo lần đầu
  Future<void> _createTables(Database db) async {
    // Bảng lưu thông tin tổng quan của Đơn hàng
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        pickup_time TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Bảng lưu chi tiết các món ăn nằm trong từng Đơn hàng
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        menu_item_id INTEGER NOT NULL,
        menu_item_name TEXT NOT NULL,
        price_at_order INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id)
      )
    ''');
  }

  /// Phương thức hỗ trợ cho Unit Test:
  /// Đóng kết nối hiện tại và mở cơ sở dữ liệu tạm thời trên RAM ([inMemoryDatabasePath]).
  /// Giúp mỗi bài test khởi chạy độc lập với dữ liệu sạch $100\%.
  @visibleForTesting
  Future<void> resetForTest() async {
    await _db?.close();
    _db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) => _createTables(db),
    );
  }
}

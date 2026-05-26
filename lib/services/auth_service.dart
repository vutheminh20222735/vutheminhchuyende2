import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _db = DatabaseService();
  User? _currentUser;

  User? get currentUser => _currentUser;

  // Đăng ký
  Future<User?> register(String phone, String password, String name) async {
    try {
      print('📝 Đang đăng ký: $phone');

      // Kiểm tra số điện thoại đã tồn tại
      final existingUser = await _db.getUserByPhone(phone);
      print('🔍 Kiểm tra user: ${existingUser != null ? "Đã tồn tại" : "Chưa tồn tại"}');

      if (existingUser != null) {
        print('❌ Số điện thoại đã tồn tại: $phone');
        return null;
      }

      // Tạo user mới
      final user = User(
        phone: phone,
        password: password,
        name: name,
        createdAt: DateTime.now(),
      );

      final id = await _db.insertUser(user);
      print('✅ Đã insert user, ID: $id');

      if (id > 0) {
        _currentUser = await _db.getUserById(id);
        await _saveUserToPrefs(_currentUser!);
        print('✅ Đăng ký thành công: ${_currentUser!.name}');
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Lỗi register: $e');
      return null;
    }
  }

  // Đăng nhập
  Future<User?> login(String phone, String password) async {
    try {
      print('📝 Đang đăng nhập: $phone');
      final user = await _db.getUserByPhone(phone);

      if (user != null) {
        print('🔍 Tìm thấy user: ${user.name}');
        if (user.password == password) {
          _currentUser = user;
          await _saveUserToPrefs(user);
          print('✅ Đăng nhập thành công');
          return user;
        } else {
          print('❌ Sai mật khẩu');
        }
      } else {
        print('❌ Không tìm thấy user');
      }
      return null;
    } catch (e) {
      print('❌ Lỗi login: $e');
      return null;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    _currentUser = null;
    await _clearUserPrefs();
  }

  // Lấy user từ SharedPreferences
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        _currentUser = await _db.getUserById(userId);
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('❌ Lỗi getCurrentUser: $e');
      return null;
    }
  }

  // Lưu user vào SharedPreferences
  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    await prefs.setString('user_phone', user.phone);
    await prefs.setString('user_name', user.name);
    await prefs.setBool('is_logged_in', true);
  }

  // Xóa user khỏi SharedPreferences
  Future<void> _clearUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
  }

  // Reset database (chỉ dùng để debug)
  Future<void> resetDatabase() async {
    await _db.resetDatabase();
    await _clearUserPrefs();
    print('✅ Đã reset database');
  }
}
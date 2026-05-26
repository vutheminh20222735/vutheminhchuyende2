import 'package:flutter/material.dart';
import 'package:quan_ly_chi_tieu/services/auth_service.dart';
import 'package:quan_ly_chi_tieu/services/database_service.dart';
import 'package:quan_ly_chi_tieu/models/wallet.dart';
import 'package:quan_ly_chi_tieu/screens/login_screen.dart';
import 'package:quan_ly_chi_tieu/utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Hàm kiểm tra số điện thoại hợp lệ (chính xác 10 số)
  bool _isValidPhone(String phone) {
    // Xóa khoảng trắng
    phone = phone.trim();
    // Kiểm tra độ dài chính xác 10 số và chỉ chứa số
    final phoneRegex = RegExp(r'^\d{10}$');
    return phoneRegex.hasMatch(phone);
  }

  // Hàm kiểm tra số điện thoại có độ dài 10 số không
  bool _isValidPhoneLength(String phone) {
    phone = phone.trim();
    return phone.length == 10 && RegExp(r'^\d+$').hasMatch(phone);
  }

  Future<void> _register() async {
    // Kiểm tra họ tên
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập họ tên'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra số điện thoại
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra định dạng số điện thoại (chính xác 10 số)
    if (!_isValidPhone(_phoneController.text)) {
      String errorMsg = '';
      if (_phoneController.text.trim().length < 10) {
        errorMsg = 'Số điện thoại không đúng định dạng!  ${10 - _phoneController.text.trim().length} số';
      } else if (_phoneController.text.trim().length > 10) {
        errorMsg = 'Số điện thoại không đúng định dạng ${_phoneController.text.trim().length - 10} số';
      } else {
        errorMsg = 'Số điện thoại không đúng! Vui lòng nhập đúng số điện thoại';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMsg'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra mật khẩu
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra mật khẩu xác nhận
    if (_confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng xác nhận mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra mật khẩu khớp
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra độ dài mật khẩu
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu phải có ít nhất 6 ký tự'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _auth.register(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (user != null && mounted) {
        // Tạo ví mặc định cho user
        await _db.insertWallet(Wallet(
          name: 'Ví chính',
          initialBalance: 0,
          isDefault: true,
          userId: user.id,
        ));

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đăng ký thành công! Vui lòng đăng nhập'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Đợi 1.5 giây rồi quay về trang đăng nhập
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Xóa toàn bộ dữ liệu trong form
          _nameController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Quay về trang đăng nhập
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else {
        // Đăng ký thất bại do số điện thoại đã tồn tại
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Số điện thoại đã được đăng ký'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Xử lý lỗi bất kỳ
      print('Lỗi đăng ký: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.purple.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng ký để bắt đầu quản lý chi tiêu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Họ tên Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Số điện thoại Field
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập đúng số điện thoại ',
                    prefixIcon: const Icon(Icons.phone_android_outlined, color: AppColors.purple),
                    counterText: '',  // Ẩn bộ đếm mặc định
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  onChanged: (value) {
                    // Kiểm tra và hiển thị lỗi realtime
                    if (value.length > 0 && value.length != 10) {
                      setState(() {});
                    }
                  },
                ),

                // Hiển thị trạng thái số điện thoại
                if (_phoneController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      _phoneController.text.length == 10
                          ? '✅ Số điện thoại hợp lệ'
                          : '❌ Số điện thoại phải có đúng 10 số (hiện tại: ${_phoneController.text.length} số)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _phoneController.text.length == 10 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Mật khẩu Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.purple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.purple,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Xác nhận mật khẩu Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.purple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.purple,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Gợi ý mật khẩu
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'Mật khẩu phải có ít nhất 6 ký tự',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Đăng ký',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
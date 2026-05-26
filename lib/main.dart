import 'package:flutter/material.dart';
import 'package:quan_ly_chi_tieu/screens/login_screen.dart';
import 'package:quan_ly_chi_tieu/screens/dashboard_screen.dart';
import 'package:quan_ly_chi_tieu/screens/currency_tools_screen.dart';
import 'package:quan_ly_chi_tieu/screens/report_screen.dart';
import 'package:quan_ly_chi_tieu/screens/settings_screen.dart';
import 'package:quan_ly_chi_tieu/services/auth_service.dart';
import 'package:quan_ly_chi_tieu/utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý chi tiêu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = await _auth.getCurrentUser();
    setState(() {
      _isLoggedIn = user != null;
      _isLoading = false;
    });
  }

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _handleLogin);
    }

    return const MainScreen();
  }
}

// MÀN HÌNH CHÍNH VỚI BOTTOM NAVIGATION BAR
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CurrencyToolsScreen(),
    const ReportScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.purple.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 24),
            selectedIcon: Icon(Icons.home, size: 24),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined, size: 24),
            selectedIcon: Icon(Icons.currency_exchange, size: 24),
            label: 'Công cụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, size: 24),
            selectedIcon: Icon(Icons.bar_chart, size: 24),
            label: 'Báo cáo',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, size: 24),
            selectedIcon: Icon(Icons.settings, size: 24),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}
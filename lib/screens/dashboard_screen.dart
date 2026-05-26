import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../widgets/mina_avatar.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'ai_chat_transaction.dart';
import 'ai_analysis_screen.dart';
import 'statistics_screen.dart';
import 'wallet_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  List<Transaction> _transactions = [];
  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  int _selectedCategoryIndex = 0;

  int? get _currentUserId => _auth.currentUser?.id;

  final List<String> _categories = ['Tất cả', 'Ăn uống', 'Mua sắm', 'Di chuyển', 'Hóa đơn', 'Giải trí'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    print('📊 Dashboard: Bắt đầu load dữ liệu');

    _wallets = await _db.getWallets(userId: _currentUserId);
    print('📊 Dashboard: Tìm thấy ${_wallets.length} ví');

    if (_wallets.isEmpty) {
      print('📊 Dashboard: Không có ví, tạo ví mới');
      final defaultWallet = Wallet(
        name: 'Ví chính',
        isDefault: true,
        userId: _currentUserId,
      );
      await _db.insertWallet(defaultWallet);
      _wallets = await _db.getWallets(userId: _currentUserId);
    }

    _currentWallet = await _db.getDefaultWallet(userId: _currentUserId);
    if (_currentWallet == null && _wallets.isNotEmpty) {
      _currentWallet = _wallets.first;
    }

    await _loadTransactions();
    setState(() => _isLoading = false);
    print('📊 Dashboard: Load dữ liệu hoàn tất');
  }

  Future<void> _loadTransactions() async {
    if (_currentWallet == null) return;

    print('📊 Dashboard: Load transactions cho ví ${_currentWallet!.id}');

    _transactions = await _db.getTransactions(
      walletId: _currentWallet!.id,
      userId: _currentUserId,
    );
    _totalIncome = await _db.getTotalIncome(
      walletId: _currentWallet!.id,
      userId: _currentUserId,
    );
    _totalExpense = await _db.getTotalExpense(
      walletId: _currentWallet!.id,
      userId: _currentUserId,
    );

    print('📊 Dashboard: Tổng thu nhập = ${Helpers.formatMoney(_totalIncome)}');
    print('📊 Dashboard: Tổng chi tiêu = ${Helpers.formatMoney(_totalExpense)}');
    print('📊 Dashboard: Số dư = ${Helpers.formatMoney(_totalIncome - _totalExpense)}');

    setState(() {});
  }

  // HÀM REFRESH DỮ LIỆU - GỌI SAU KHI THÊM/XÓA GIAO DỊCH
  Future<void> _refreshData() async {
    print('🔄 Dashboard: Refresh dữ liệu...');
    await _loadData();
    setState(() {});
    print('🔄 Dashboard: Refresh hoàn tất');
  }

  List<Transaction> get _filteredTransactions {
    if (_selectedCategoryIndex == 0) return _transactions;
    final category = _categories[_selectedCategoryIndex];
    return _transactions.where((t) => t.category == category).toList();
  }

  double get _balance => _totalIncome - _totalExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildMinaHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildStatsCard(),
              ),
              // ========== THÊM MỚI: AI ANALYSIS CARD ==========
              SliverToBoxAdapter(
                child: _buildAIAnalysisCard(),
              ),
              // ========== THÊM MỚI: STATISTICS CARD ==========
              SliverToBoxAdapter(
                child: _buildStatisticsCard(),
              ),
              SliverToBoxAdapter(
                child: _buildExpenseChart(),
              ),
              SliverToBoxAdapter(
                child: _buildCategoryFilter(),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (_isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_filteredTransactions.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildTransactionItem(_filteredTransactions[index]);
                  },
                  childCount: _isLoading ? 0 : _filteredTransactions.length,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('➕ Dashboard: Mở chat với Mina');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIChatTransaction(
                walletId: _currentWallet?.id,
                userId: _currentUserId,
                onSave: () {
                  print('🔄 Dashboard: Callback từ AI Chat - refresh dữ liệu');
                  _refreshData();
                },
              ),
            ),
          );
          if (result == null) {
            print('🔄 Dashboard: Quay lại từ chat, refresh lại');
            _refreshData();
          }
        },
        backgroundColor: const Color(0xFFFF69B4),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  // ========== PHẦN MỚI: CARD PHÂN TÍCH AI ==========
  Widget _buildAIAnalysisCard() {
    // Tính toán số liệu cơ bản cho AI
    final expenseTransactions = _transactions.where((t) => t.type == 'expense').toList();
    final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Thống kê theo danh mục chi tiêu
    Map<String, double> categorySpending = {};
    for (var t in expenseTransactions) {
      categorySpending[t.category] = (categorySpending[t.category] ?? 0) + t.amount;
    }

    // Tìm danh mục chi nhiều nhất
    String topCategory = '';
    double topAmount = 0;
    categorySpending.forEach((cat, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = cat;
      }
    });

    // Tỷ lệ tiết kiệm
    final savingRate = _totalIncome > 0 ? ((_totalIncome - totalExpense) / _totalIncome * 100) : 0;

    // Lời khuyên AI dựa trên dữ liệu
    String aiAdvice = '';
    String aiIcon = '🤖';
    Color aiColor = const Color(0xFF9C27B0);

    if (_transactions.isEmpty) {
      aiAdvice = 'Chưa có dữ liệu. Hãy thêm giao dịch để tôi phân tích giúp bạn nhé! 💡';
      aiIcon = '💡';
      aiColor = Colors.orange;
    } else if (savingRate < 0) {
      aiAdvice = '⚠️ Cảnh báo: Bạn đang chi tiêu nhiều hơn thu nhập ${(-savingRate).toStringAsFixed(0)}%! Hãy cắt giảm chi tiêu không cần thiết.';
      aiIcon = '⚠️';
      aiColor = Colors.red;
    } else if (savingRate < 20) {
      aiAdvice = '📊 Bạn tiết kiệm được ${savingRate.toStringAsFixed(0)}% thu nhập. Hãy cố gắng đạt mục tiêu 20% nhé!';
      aiIcon = '📊';
      aiColor = Colors.orange;
    } else if (topCategory.isNotEmpty) {
      aiAdvice = '🍽️ Bạn chi nhiều nhất cho "$topCategory" với ${Helpers.formatMoney(topAmount)}. Cân nhắc giảm khoản này để tiết kiệm hơn.';
      aiIcon = '💰';
      aiColor = const Color(0xFF9C27B0);
    } else {
      aiAdvice = '🎉 Tuyệt vời! Bạn đang quản lý tài chính rất tốt. Hãy duy trì nhé!';
      aiIcon = '🎉';
      aiColor = Colors.green;
    }

    return GestureDetector(
      onTap: () {
        // Nhấn vào để xem phân tích chi tiết hơn
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIAnalysisScreen(
              transactions: _transactions,
              totalIncome: _totalIncome,
              totalExpense: _totalExpense,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [aiColor, aiColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: aiColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(aiIcon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Phân tích chi tiêu với AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aiAdvice,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xem chi tiết →',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== PHẦN MỚI: CARD THỐNG KÊ NHANH ==========
  Widget _buildStatisticsCard() {
    // Thống kê số liệu
    final expenseTransactions = _transactions.where((t) => t.type == 'expense').toList();
    final incomeTransactions = _transactions.where((t) => t.type == 'income').toList();

    final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncomeAmount = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Thống kê theo tháng hiện tại
    final now = DateTime.now();
    final currentMonthExpense = expenseTransactions.where((t) =>
    t.date.year == now.year && t.date.month == now.month
    ).fold(0.0, (sum, t) => sum + t.amount);

    final currentMonthIncome = incomeTransactions.where((t) =>
    t.date.year == now.year && t.date.month == now.month
    ).fold(0.0, (sum, t) => sum + t.amount);

    // Số giao dịch
    final transactionCount = _transactions.length;
    final expenseCount = expenseTransactions.length;
    final incomeCount = incomeTransactions.length;

    // Biểu đồ nhỏ (thanh tiến trình)
    final expensePercent = totalIncomeAmount > 0 ? (totalExpense / totalIncomeAmount) : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StatisticsScreen(transactions: _transactions),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'Thống kê nhanh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Spacer(),
                Text(
                  'Xem chi tiết →',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 2 cột số liệu
            Row(
              children: [
                Expanded(
                  child: _buildStatQuickItem(
                    'Tổng giao dịch',
                    '$transactionCount',
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatQuickItem(
                    'Khoản thu',
                    '$incomeCount',
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatQuickItem(
                    'Khoản chi',
                    '$expenseCount',
                    Icons.arrow_downward,
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Thống kê tháng hiện tại
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Thu tháng này',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.formatMoney(currentMonthIncome),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Chi tháng này',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.formatMoney(currentMonthExpense),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Chênh lệch',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Helpers.formatMoney(currentMonthIncome - currentMonthExpense),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (currentMonthIncome - currentMonthExpense) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Thanh tiến trình thu/chi
            Row(
              children: [
                Expanded(
                  flex: (expensePercent * 100).toInt(),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        bottomLeft: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (expensePercent * 100).toInt(),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi ${(expensePercent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
                Text(
                  'Thu ${((1 - expensePercent) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper cho thống kê nhanh
  Widget _buildStatQuickItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // Phần header (giữ nguyên)
  Widget _buildMinaHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          MinaAvatar(
            size: 60,
            isWaving: true,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xin chào,',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  _auth.currentUser?.name ?? 'Người dùng',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hôm nay bạn thế nào? 🌸',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.pink.shade400,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'wallet',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 20),
                    SizedBox(width: 10),
                    Text('Quản lý ví'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'wallet') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                ).then((_) => _refreshData());
              }
            },
          ),
        ],
      ),
    );
  }

  // Phần stats card (giữ nguyên)
  Widget _buildStatsCard() {
    final saving = _totalIncome - _totalExpense;
    final savingRate = _totalIncome > 0 ? (saving / _totalIncome) * 100 : 0;

    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng số dư',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      saving >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Thay đổi ròng ${saving >= 0 ? '+' : ''}${Helpers.formatMoney(saving)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatMoney(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                'Thu nhập',
                _totalIncome,
                const Color(0xFF4CD964),
                Icons.arrow_upward,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                'Chi phí',
                _totalExpense,
                const Color(0xFFFF3B30),
                Icons.arrow_downward,
              ),
              const SizedBox(width: 20),
              _buildStatItem(
                'Tiết kiệm',
                saving,
                const Color(0xFFFFD93D),
                Icons.savings,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Container(
                  width: (_totalExpense / (_totalIncome + 0.01)) * MediaQuery.of(context).size.width * 0.8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã chi ${savingRate.toStringAsFixed(1)}% thu nhập',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            Helpers.formatMoney(amount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Phần expense chart (giữ nguyên)
  Widget _buildExpenseChart() {
    final Map<String, double> categorySpending = {};
    for (var t in _transactions.where((t) => t.type == 'expense')) {
      categorySpending[t.category] = (categorySpending[t.category] ?? 0) + t.amount;
    }

    final categories = categorySpending.keys.toList();
    final amounts = categories.map((c) => categorySpending[c]!).toList();
    final total = amounts.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'Chưa có dữ liệu chi tiêu',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân tích chi tiêu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 15),
          ...List.generate(categories.length > 5 ? 5 : categories.length, (index) {
            final category = categories[index];
            final amount = amounts[index];
            final percentage = (amount / total) * 100;
            final categoryInfo = Categories.getCategoryInfo(category);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        categoryInfo['icon'] as IconData,
                        color: categoryInfo['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        Helpers.formatMoney(amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: categoryInfo['color'] as Color,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(_categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryIndex = selected ? index : 0;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF6C63FF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final categoryInfo = Categories.getCategoryInfo(transaction.category);

    return Dismissible(
      key: Key(transaction.id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _db.deleteTransaction(transaction.id!);
        await _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa giao dịch')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (categoryInfo['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                categoryInfo['icon'] as IconData,
                color: categoryInfo['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.category} • ${transaction.formattedDate}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${transaction.formattedAmount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(Icons.receipt, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để trò chuyện với Mina và thêm giao dịch',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
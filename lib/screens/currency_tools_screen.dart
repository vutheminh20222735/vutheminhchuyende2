import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/finance_tool.dart';
import '../models/transaction.dart';

class CurrencyToolsScreen extends StatefulWidget {
  const CurrencyToolsScreen({super.key});

  @override
  State<CurrencyToolsScreen> createState() => _CurrencyToolsScreenState();
}

class _CurrencyToolsScreenState extends State<CurrencyToolsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  late TabController _tabController;
  int _selectedTab = 0;
  List<Budget> _budgets = [];
  List<SavingGoal> _savingGoals = [];
  List<Debt> _debts = [];
  List<Challenge> _challenges = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  int? get _currentUserId => _auth.currentUser?.id;

  final List<String> _expenseCategories = [
    'Ăn uống', 'Mua sắm', 'Di chuyển', 'Hóa đơn',
    'Giải trí', 'Sức khỏe', 'Giáo dục', 'Khác'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadTransactions();
    await _loadBudgets();
    await _loadSavingGoals();
    await _loadDebts();
    await _loadChallenges();
    setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    _transactions = await _db.getTransactions(userId: _currentUserId);
  }

  double _getSpentByCategory(String category) {
    return _transactions
        .where((t) => t.type == 'expense' && t.category == category)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _updateBudgetSpent() async {
    for (var i = 0; i < _budgets.length; i++) {
      final spent = _getSpentByCategory(_budgets[i].category);
      _budgets[i].spent = spent;
    }
    await _saveBudgets();
    setState(() {});
  }

  Future<void> _loadBudgets() async {
    _budgets = [
      Budget(
        category: 'Ăn uống',
        budgetLimit: 3000000,
        spent: _getSpentByCategory('Ăn uống'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Mua sắm',
        budgetLimit: 2000000,
        spent: _getSpentByCategory('Mua sắm'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Di chuyển',
        budgetLimit: 1000000,
        spent: _getSpentByCategory('Di chuyển'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Hóa đơn',
        budgetLimit: 1500000,
        spent: _getSpentByCategory('Hóa đơn'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Giải trí',
        budgetLimit: 1000000,
        spent: _getSpentByCategory('Giải trí'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Sức khỏe',
        budgetLimit: 1000000,
        spent: _getSpentByCategory('Sức khỏe'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Giáo dục',
        budgetLimit: 1000000,
        spent: _getSpentByCategory('Giáo dục'),
        createdAt: DateTime.now(),
      ),
      Budget(
        category: 'Khác',
        budgetLimit: 500000,
        spent: _getSpentByCategory('Khác'),
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _loadSavingGoals() async {
    _savingGoals = [
      SavingGoal(
        name: 'Du lịch Đà Nẵng',
        targetAmount: 5000000,
        currentAmount: 2000000,
        targetDate: DateTime(2024, 12, 31),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      SavingGoal(
        name: 'Mua điện thoại mới',
        targetAmount: 10000000,
        currentAmount: 3000000,
        targetDate: DateTime(2024, 10, 31),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  Future<void> _loadDebts() async {
    _debts = [
      Debt(
        name: 'Vay mua xe',
        totalAmount: 20000000,
        paidAmount: 5000000,
        dueDate: DateTime(2024, 6, 30),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Debt(
        name: 'Thẻ tín dụng',
        totalAmount: 5000000,
        paidAmount: 2000000,
        dueDate: DateTime(2024, 4, 30),
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }

  Future<void> _loadChallenges() async {
    _challenges = [
      Challenge(
        name: 'Tiết kiệm 10 triệu',
        description: 'Thử thách 30 ngày',
        targetAmount: 10000000,
        currentAmount: 4000000,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _saveBudgets() async {
    print('✅ Đã lưu ngân sách');
  }

  Future<void> _saveSavingGoals() async {
    print('✅ Đã lưu mục tiêu tiết kiệm');
  }

  Future<void> _saveDebts() async {
    print('✅ Đã lưu món nợ');
  }

  Future<void> _saveChallenges() async {
    print('✅ Đã lưu thử thách');
  }

  void _showEditBudgetDialog(Budget budget, int index) {
    final controller = TextEditingController(text: budget.budgetLimit.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Điều chỉnh ngân sách - ${budget.category}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đã chi: ${Helpers.formatMoney(budget.spent)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Giới hạn ngân sách (₫)',
                border: OutlineInputBorder(),
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text) ?? 0;
              if (newLimit > 0) {
                setState(() {
                  _budgets[index].budgetLimit = newLimit;
                });
                _saveBudgets();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật ngân sách ${budget.category}')),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    String selectedCategory = _expenseCategories.first;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Thêm ngân sách'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                  items: _expenseCategories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Giới hạn (₫)', border: OutlineInputBorder(), prefixText: '₫ '),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              TextButton(
                onPressed: () {
                  if (amountController.text.isNotEmpty) {
                    final newBudget = Budget(
                      category: selectedCategory,
                      budgetLimit: double.parse(amountController.text),
                      spent: _getSpentByCategory(selectedCategory),
                      createdAt: DateTime.now(),
                    );
                    setState(() {
                      _budgets.add(newBudget);
                    });
                    _saveBudgets();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm ngân sách')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSavingDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Thêm mục tiêu tiết kiệm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên mục tiêu',
                    hintText: 'VD: Du lịch, Mua xe, ...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền mục tiêu (₫)',
                    border: OutlineInputBorder(),
                    prefixText: '₫ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    setState(() {
                      _savingGoals.add(SavingGoal(
                        name: nameController.text,
                        targetAmount: double.parse(amountController.text),
                        currentAmount: 0,
                        targetDate: DateTime.now(),
                        createdAt: DateTime.now(),
                      ));
                    });
                    _saveSavingGoals();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm mục tiêu tiết kiệm')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDebtDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Thêm món nợ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên khoản nợ',
                    hintText: 'VD: Vay ngân hàng, Nợ bạn bè, ...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Tổng số tiền (₫)',
                    border: OutlineInputBorder(),
                    prefixText: '₫ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text('📅 Hạn trả: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setStateDialog(() => selectedDate = date);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    setState(() {
                      _debts.add(Debt(
                        name: nameController.text,
                        totalAmount: double.parse(amountController.text),
                        paidAmount: 0,
                        dueDate: selectedDate,
                        createdAt: DateTime.now(),
                      ));
                    });
                    _saveDebts();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm món nợ')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddChallengeDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Thêm thử thách'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên thử thách',
                      hintText: 'VD: Thử thách 30 ngày',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Mô tả chi tiết về thử thách',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền mục tiêu (₫)',
                      border: OutlineInputBorder(),
                      prefixText: '₫ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text('📅 Ngày bắt đầu: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setStateDialog(() => startDate = date);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('📅 Ngày kết thúc: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: startDate.add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setStateDialog(() => endDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    setState(() {
                      _challenges.add(Challenge(
                        name: nameController.text,
                        description: descriptionController.text,
                        targetAmount: double.parse(amountController.text),
                        currentAmount: 0,
                        startDate: startDate,
                        endDate: endDate,
                        createdAt: DateTime.now(),
                      ));
                    });
                    _saveChallenges();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã thêm thử thách')),
                    );
                  }
                },
                child: const Text('Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateAmountDialog(String type, dynamic item, int index) {
    final amountController = TextEditingController();
    String title = '';
    String label = '';

    if (type == 'saving') {
      title = '💰 Thêm tiền tiết kiệm';
      label = 'Số tiền thêm (₫)';
    } else if (type == 'debt') {
      title = '💳 Thanh toán nợ';
      label = 'Số tiền thanh toán (₫)';
    } else {
      title = '🏆 Thêm tiền vào thử thách';
      label = 'Số tiền thêm (₫)';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                prefixText: '₫ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amount = double.parse(amountController.text);
                setState(() {
                  if (type == 'saving') {
                    _savingGoals[index].currentAmount += amount;
                  } else if (type == 'debt') {
                    _debts[index].paidAmount += amount;
                  } else if (type == 'challenge') {
                    _challenges[index].currentAmount += amount;
                  }
                });
                if (type == 'saving') _saveSavingGoals();
                if (type == 'debt') _saveDebts();
                if (type == 'challenge') _saveChallenges();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã ${type == 'saving' ? "thêm" : "thanh toán"} ${Helpers.formatMoney(amount)}')),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  int _getDaysLeft(DateTime targetDate) {
    return targetDate.difference(DateTime.now()).inDays;
  }

  Color _getDueDateColor(DateTime dueDate) {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red;
    if (daysLeft < 7) return Colors.orange;
    return Colors.green;
  }

  String _getDueDateMessage(DateTime dueDate) {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return '⚠️ Đã quá hạn thanh toán!';
    if (daysLeft == 0) return '⚠️ Hôm nay là hạn thanh toán!';
    if (daysLeft < 7) return '⚠️ Còn $daysLeft ngày đến hạn thanh toán';
    return '✅ Còn $daysLeft ngày đến hạn thanh toán';
  }

  void _showDeleteConfirmDialog(String type, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa mục này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              setState(() {
                if (type == 'budget') _budgets.removeAt(index);
                if (type == 'saving') _savingGoals.removeAt(index);
                if (type == 'debt') _debts.removeAt(index);
                if (type == 'challenge') _challenges.removeAt(index);
              });
              if (type == 'budget') _saveBudgets();
              if (type == 'saving') _saveSavingGoals();
              if (type == 'debt') _saveDebts();
              if (type == 'challenge') _saveChallenges();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài chính'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Ngân sách'),
            Tab(icon: Icon(Icons.savings), text: 'Tiết kiệm'),
            Tab(icon: Icon(Icons.credit_card), text: 'Món nợ'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Thử thách'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetTab(),
          _buildSavingTab(),
          _buildDebtTab(),
          _buildChallengeTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildSummaryCard(
            title: 'Tổng ngân sách',
            amount: _budgets.fold(0.0, (sum, b) => sum + b.budgetLimit),
            icon: Icons.pie_chart,
            color: Colors.blue,
          ),
          const SizedBox(height: 15),
          const Text(
            'Ngân sách theo danh mục',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._budgets.asMap().entries.map((entry) => _buildBudgetItem(entry.value, entry.key)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddBudgetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm ngân sách'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(Budget budget, int index) {
    double percentage = budget.percentage;
    Color color = percentage > 80 ? Colors.red : percentage > 50 ? Colors.orange : Colors.green;

    return Dismissible(
      key: Key(budget.category),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _showDeleteConfirmDialog('budget', index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showEditBudgetDialog(budget, index),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getCategoryIcon(budget.category), color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(budget.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Đã chi ${Helpers.formatMoney(budget.spent)} / ${Helpers.formatMoney(budget.budgetLimit)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                        const SizedBox(height: 4),
                        Text(
                          'Còn ${Helpers.formatMoney(budget.remaining)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(budget.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildSummaryCard(
            title: 'Tổng tiết kiệm',
            amount: _savingGoals.fold(0.0, (sum, s) => sum + s.currentAmount),
            icon: Icons.savings,
            color: Colors.green,
          ),
          const SizedBox(height: 15),
          const Text(
            'Mục tiêu tiết kiệm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._savingGoals.asMap().entries.map((entry) => _buildSavingItem(entry.value, entry.key)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddSavingDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm mục tiêu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingItem(SavingGoal goal, int index) {
    double percentage = goal.percentage;
    final daysLeft = _getDaysLeft(goal.targetDate);
    final isUrgent = daysLeft < 30 && daysLeft > 0;

    return Dismissible(
      key: Key(goal.name),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _showDeleteConfirmDialog('saving', index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showUpdateAmountDialog('saving', goal, index),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.track_changes, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Mục tiêu: ${Helpers.formatMoney(goal.targetAmount)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã tiết kiệm: ${Helpers.formatMoney(goal.currentAmount)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sắp đến hạn!',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Còn $daysLeft ngày',
                  style: TextStyle(
                    fontSize: 11,
                    color: daysLeft < 0 ? Colors.red : (daysLeft < 30 ? Colors.orange : Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(goal.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showUpdateAmountDialog('saving', goal, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('+ Thêm tiền'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          _buildSummaryCard(
            title: 'Tổng nợ',
            amount: _debts.fold(0.0, (sum, d) => sum + d.remaining),
            icon: Icons.credit_card,
            color: Colors.red,
          ),
          const SizedBox(height: 15),
          const Text(
            'Danh sách món nợ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._debts.asMap().entries.map((entry) => _buildDebtItem(entry.value, entry.key)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddDebtDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm món nợ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtItem(Debt debt, int index) {
    double percentage = debt.percentage;
    final daysLeft = _getDaysLeft(debt.dueDate);
    final isOverdue = daysLeft < 0;
    final isUrgent = daysLeft >= 0 && daysLeft < 7;

    return Dismissible(
      key: Key(debt.name),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _showDeleteConfirmDialog('debt', index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showUpdateAmountDialog('debt', debt, index),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOverdue ? Icons.warning_amber : Icons.warning,
                        color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.red),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Hạn: ${DateFormat('dd/MM/yyyy').format(debt.dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.red),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã trả: ${Helpers.formatMoney(debt.paidAmount)} / ${Helpers.formatMoney(debt.totalAmount)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'QUÁ HẠN!',
                          style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sắp đến hạn!',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOverdue
                      ? '⚠️ Đã quá hạn ${-daysLeft} ngày'
                      : '📅 Còn $daysLeft ngày',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(debt.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showUpdateAmountDialog('debt', debt, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOverdue ? Colors.red : (isUrgent ? Colors.orange : AppColors.primary),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Thanh toán'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const Text(
            '🏆 Thử thách đang diễn ra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ..._challenges.asMap().entries.map((entry) => _buildChallengeItem(entry.value, entry.key)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddChallengeDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm thử thách'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(Challenge challenge, int index) {
    double percentage = challenge.percentage;
    final daysLeft = challenge.daysLeft;
    final isUrgent = daysLeft < 7 && daysLeft > 0;
    final isOverdue = daysLeft < 0;

    return Dismissible(
      key: Key(challenge.name),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _showDeleteConfirmDialog('challenge', index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => _showUpdateAmountDialog('challenge', challenge, index),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(challenge.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(challenge.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.orange,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${Helpers.formatMoney(challenge.currentAmount)} / ${Helpers.formatMoney(challenge.targetAmount)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Sắp kết thúc!',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Còn $daysLeft ngày',
                  style: TextStyle(
                    fontSize: 11,
                    color: daysLeft < 0 ? Colors.red : (daysLeft < 7 ? Colors.orange : Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '📅 Tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(challenge.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showUpdateAmountDialog('challenge', challenge, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('+ Thêm tiền'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required double amount, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Text(Helpers.formatMoney(amount), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống': return Icons.restaurant;
      case 'Mua sắm': return Icons.shopping_bag;
      case 'Di chuyển': return Icons.directions_car;
      case 'Hóa đơn': return Icons.receipt;
      case 'Giải trí': return Icons.movie;
      case 'Sức khỏe': return Icons.favorite;
      case 'Giáo dục': return Icons.school;
      default: return Icons.category;
    }
  }

  void _showAddDialog() {
    switch (_selectedTab) {
      case 0: _showAddBudgetDialog(); break;
      case 1: _showAddSavingDialog(); break;
      case 2: _showAddDebtDialog(); break;
      case 3: _showAddChallengeDialog(); break;
    }
  }
}
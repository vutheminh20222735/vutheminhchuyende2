import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseService _db = DatabaseService();
  List<Transaction> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _categorySpending = {};
  bool _isLoading = true;
  String _selectedPeriod = 'Tháng này';

  final List<String> _periods = ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay', 'Tất cả'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _transactions = await _db.getTransactions();
    _totalIncome = await _db.getTotalIncome();
    _totalExpense = await _db.getTotalExpense();
    _categorySpending = await _db.getCategorySpending();
    setState(() => _isLoading = false);
  }

  List<Transaction> _filterTransactions() {
    final now = DateTime.now();
    return _transactions.where((t) {
      switch (_selectedPeriod) {
        case 'Hôm nay':
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        case 'Tuần này':
          final start = now.subtract(Duration(days: now.weekday - 1));
          final end = start.add(const Duration(days: 7));
          return t.date.isAfter(start) && t.date.isBefore(end);
        case 'Tháng này':
          return t.date.year == now.year && t.date.month == now.month;
        case 'Năm nay':
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  double _getFilteredIncome() {
    return _filterTransactions()
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getFilteredExpense() {
    return _filterTransactions()
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final filteredIncome = _getFilteredIncome();
    final filteredExpense = _getFilteredExpense();
    final filteredBalance = filteredIncome - filteredExpense;
    final filteredTransactions = _filterTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            // Chọn thời gian
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  items: _periods.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tổng quan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tổng quan',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildReportItem('Thu nhập', Helpers.formatMoney(filteredIncome), Colors.green),
                      _buildReportItem('Chi tiêu', Helpers.formatMoney(filteredExpense), Colors.red),
                      _buildReportItem('Số dư', Helpers.formatMoney(filteredBalance), Colors.white),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Top chi tiêu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top khoản chi lớn nhất',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._getTopExpenses(filteredTransactions).map((t) => ListTile(
                      leading: Icon(Icons.trending_down, color: Colors.red),
                      title: Text(t.title),
                      subtitle: Text('${t.category} • ${t.formattedDate}'),
                      trailing: Text(
                        Helpers.formatMoney(t.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    )),
                    if (_getTopExpenses(filteredTransactions).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Chưa có dữ liệu')),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Giao dịch gần đây
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giao dịch trong kỳ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTransactions.length > 10 ? 10 : filteredTransactions.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final t = filteredTransactions[index];
                        final isExpense = t.type == 'expense';
                        return ListTile(
                          leading: Icon(
                            isExpense ? Icons.trending_down : Icons.trending_up,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                          title: Text(t.title),
                          subtitle: Text('${t.category} • ${t.formattedDate}'),
                          trailing: Text(
                            '${isExpense ? '-' : '+'}${Helpers.formatMoney(t.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<Transaction> _getTopExpenses(List<Transaction> transactions) {
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(5).toList();
  }
}
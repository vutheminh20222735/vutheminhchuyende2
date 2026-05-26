import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class StatisticsScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const StatisticsScreen({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán số liệu thống kê
    final expenseTransactions = transactions.where((t) => t.type == 'expense').toList();
    final incomeTransactions = transactions.where((t) => t.type == 'income').toList();

    final totalExpense = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Thống kê theo danh mục chi
    Map<String, double> categoryData = {};
    for (var t in expenseTransactions) {
      categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
    }

    // Thống kê theo tháng
    Map<String, double> monthlyExpense = {};
    Map<String, double> monthlyIncome = {};
    for (var t in transactions) {
      final key = '${t.date.month}/${t.date.year}';
      if (t.type == 'expense') {
        monthlyExpense[key] = (monthlyExpense[key] ?? 0) + t.amount;
      } else {
        monthlyIncome[key] = (monthlyIncome[key] ?? 0) + t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiêu'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Biểu đồ tròn', icon: Icon(Icons.pie_chart)),
                Tab(text: 'Biểu đồ cột', icon: Icon(Icons.bar_chart)),
                Tab(text: 'Chi tiết', icon: Icon(Icons.list)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Biểu đồ tròn
                  _buildPieChart(categoryData, totalExpense),

                  // Tab 2: Biểu đồ cột
                  _buildBarChart(monthlyExpense, monthlyIncome),

                  // Tab 3: Chi tiết dạng bảng
                  _buildStatisticsTable(totalIncome, totalExpense, expenseTransactions.length, incomeTransactions.length),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryData, double totalExpense) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu chi tiêu'),
      );
    }

    final colors = [
      const Color(0xFFFF6384), const Color(0xFF36A2EB), const Color(0xFFFFCE56),
      const Color(0xFF4BC0C0), const Color(0xFF9966FF), const Color(0xFFFF9F40),
      const Color(0xFF66CC66), const Color(0xFFFF6699),
    ];

    int index = 0;
    final pieSections = categoryData.entries.map((entry) {
      final percent = (entry.value / totalExpense) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        color: colors[index % colors.length],
      );
      index++;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sections: pieSections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> monthlyExpense, Map<String, double> monthlyIncome) {
    if (monthlyExpense.isEmpty && monthlyIncome.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu giao dịch'),
      );
    }

    // Lấy danh sách các tháng
    final allMonths = {...monthlyExpense.keys, ...monthlyIncome.keys}.toList();
    allMonths.sort((a, b) {
      final aParts = a.split('/');
      final bParts = b.split('/');
      final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
      final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
      return aDate.compareTo(bDate);
    });

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < allMonths.length; i++) {
      final month = allMonths[i];
      final expense = monthlyExpense[month] ?? 0;
      final income = monthlyIncome[month] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: expense,
              color: Colors.red,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: income,
              color: Colors.green,
              width: 15,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < allMonths.length) {
                    return Text(allMonths[index], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildStatisticsTable(double totalIncome, double totalExpense, int expenseCount, int incomeCount) {
    final saving = totalIncome - totalExpense;
    final savingRate = totalIncome > 0 ? (saving / totalIncome * 100) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                _buildStatRow('Tổng thu nhập', Helpers.formatMoney(totalIncome), Colors.green),
                _buildStatRow('Tổng chi tiêu', Helpers.formatMoney(totalExpense), Colors.red),
                _buildStatRow('Tiết kiệm', Helpers.formatMoney(saving), saving >= 0 ? Colors.green : Colors.red),
                _buildStatRow('Tỷ lệ tiết kiệm', '${savingRate.toStringAsFixed(1)}%', savingRate >= 20 ? Colors.green : Colors.orange),
                const Divider(),
                _buildStatRow('Số giao dịch thu', '$incomeCount', Colors.green),
                _buildStatRow('Số giao dịch chi', '$expenseCount', Colors.red),
                _buildStatRow('Tổng số giao dịch', '${transactions.length}', const Color(0xFF6C63FF)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '💡 Mẹo tiết kiệm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Theo dõi chi tiêu hàng ngày để kiểm soát dòng tiền'),
                SizedBox(height: 8),
                Text('• Đặt mục tiêu tiết kiệm 20% thu nhập mỗi tháng'),
                SizedBox(height: 8),
                Text('• Cắt giảm các khoản chi không cần thiết như ăn uống bên ngoài'),
                SizedBox(height: 8),
                Text('• Sử dụng ứng dụng để ghi chép đầy đủ các khoản thu/chi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
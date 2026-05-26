import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class AIAnalysisScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;

  const AIAnalysisScreen({
    super.key,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán số liệu phân tích
    final expenseTransactions = transactions.where((t) => t.type == 'expense').toList();
    final totalExpenseAmount = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

    // Thống kê theo danh mục
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
    final saving = totalIncome - totalExpenseAmount;
    final savingRate = totalIncome > 0 ? (saving / totalIncome * 100) : 0;

    // Phân tích lời khuyên
    String analysis = '';
    if (transactions.isEmpty) {
      analysis = 'Bạn chưa có giao dịch nào. Hãy thêm giao dịch để được phân tích chi tiết nhé!';
    } else if (saving < 0) {
      analysis = '⚠️ CẢNH BÁO: Bạn đang chi tiêu nhiều hơn thu nhập ${(-savingRate).toStringAsFixed(0)}%!\n\n'
          '🔍 Nguyên nhân chính: Chi tiêu nhiều nhất cho "$topCategory" với ${Helpers.formatMoney(topAmount)}.\n\n'
          '💡 Lời khuyên: Hãy cắt giảm 20% chi phí cho danh mục này và lập kế hoạch chi tiêu hợp lý hơn.';
    } else if (savingRate < 20) {
      analysis = '📊 Bạn tiết kiệm được ${savingRate.toStringAsFixed(0)}% thu nhập.\n\n'
          '🔍 Điểm mạnh: Bạn đang kiểm soát chi tiêu khá tốt.\n'
          '🔍 Điểm yếu: Tỷ lệ tiết kiệm chưa đạt mục tiêu 20%.\n\n'
          '💡 Lời khuyên: Hãy cố gắng cắt giảm 5-10% chi phí không cần thiết để nâng tỷ lệ tiết kiệm.';
    } else {
      analysis = '🎉 TUYỆT VỜI! Bạn đang quản lý tài chính rất tốt.\n\n'
          '✅ Bạn tiết kiệm được ${savingRate.toStringAsFixed(0)}% thu nhập.\n'
          '✅ Chi tiêu được phân bổ hợp lý.\n\n'
          '💡 Lời khuyên: Hãy duy trì thói quen này và cân nhắc đầu tư để sinh lời từ khoản tiết kiệm.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích chi tiêu với AI'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card thông tin tổng quan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'AI Financial Analysis',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAIMetric('Tổng thu', Helpers.formatMoney(totalIncome), Colors.green),
                      _buildAIMetric('Tổng chi', Helpers.formatMoney(totalExpenseAmount), Colors.red),
                      _buildAIMetric('Tiết kiệm', Helpers.formatMoney(saving), saving >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card phân tích chi tiết
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1), // SỬA: withOpacity -> withValues
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
                      Icon(Icons.analytics, color: Color(0xFF6C63FF)),
                      SizedBox(width: 8),
                      Text(
                        'Kết quả phân tích',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      analysis,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top 3 danh mục chi nhiều nhất
                  if (categorySpending.isNotEmpty) ...[
                    const Text(
                      '📊 Top danh mục chi tiêu nhiều nhất',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    // SỬA: Dùng vòng lặp for thay vì .map() trực tiếp
                    ..._buildTopCategories(categorySpending, totalExpenseAmount),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HÀM MỚI: Tạo danh sách Widget cho top danh mục
  List<Widget> _buildTopCategories(Map<String, double> categorySpending, double totalExpenseAmount) {
    final List<Widget> widgets = [];

    // Sắp xếp và lấy top 3
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(3);

    for (var entry in topEntries) {
      final percent = (entry.value / totalExpenseAmount * 100);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    '${Helpers.formatMoney(entry.value)} (${percent.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF9C27B0),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildAIMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
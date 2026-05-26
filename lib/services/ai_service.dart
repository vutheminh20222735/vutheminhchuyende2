import '../models/transaction.dart';
import '../utils/helpers.dart';

class AIService {
  // Phân tích chi tiêu và trả về thông tin tổng quan
  static Map<String, dynamic> analyzeSpending(
      List<Transaction> transactions,
      double totalIncome,
      double totalExpense,
      ) {
    double savingRate = totalIncome > 0
        ? (totalIncome - totalExpense) / totalIncome * 100
        : 0;

    // Phân tích theo danh mục
    Map<String, double> categorySpending = {};
    for (var t in transactions.where((t) => t.type == 'expense')) {
      categorySpending[t.category] = (categorySpending[t.category] ?? 0) + t.amount;
    }

    // Tìm danh mục chi nhiều nhất
    String topCategory = '';
    double topAmount = 0;
    categorySpending.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });

    // Tạo gợi ý
    List<String> suggestions = [];

    if (savingRate < 0) {
      suggestions.add('⚠️ Bạn đang chi tiêu nhiều hơn thu nhập!');
      suggestions.add('💡 Hãy cắt giảm chi tiêu cho "$topCategory"');
      suggestions.add('📉 Giảm 20% chi tiêu sẽ giúp cân bằng thu chi');
    } else if (savingRate < 10) {
      suggestions.add('📊 Tỷ lệ tiết kiệm: ${savingRate.toStringAsFixed(1)}%');
      suggestions.add('💡 Mục tiêu: Tiết kiệm 10-20% thu nhập');
      suggestions.add('🎯 Giảm 10% chi tiêu cho "$topCategory"');
    } else if (savingRate < 20) {
      suggestions.add('🎯 Tốt! Tiết kiệm ${savingRate.toStringAsFixed(1)}%');
      suggestions.add('💡 Hãy duy trì và tăng dần tỷ lệ tiết kiệm');
      suggestions.add('💰 Đầu tư số tiền tiết kiệm để sinh lời');
    } else {
      suggestions.add('🌟 Xuất sắc! Tiết kiệm ${savingRate.toStringAsFixed(1)}%');
      suggestions.add('💡 Bạn đang quản lý tài chính rất tốt!');
      suggestions.add('🚀 Cân nhắc đầu tư để gia tăng tài sản');
    }

    // Dự đoán
    double monthlySaving = totalIncome - totalExpense;
    double yearSaving = monthlySaving * 12;
    double fiveYearSaving = yearSaving * 5;

    return {
      'savingRate': savingRate,
      'topCategory': topCategory,
      'topAmount': topAmount,
      'monthlySaving': monthlySaving,
      'yearSaving': yearSaving,
      'fiveYearSaving': fiveYearSaving,
      'suggestions': suggestions,
      'categorySpending': categorySpending,
      'totalTransactions': transactions.length,
      'avgExpense': totalExpense / (transactions.where((t) => t.type == 'expense').length + 1),
    };
  }

  // Lấy lời khuyên từ AI
  static String getAdvice(Map<String, dynamic> analysis) {
    double savingRate = analysis['savingRate'];
    double monthlySaving = analysis['monthlySaving'];
    double totalTransactions = analysis['totalTransactions'];

    // Nếu chưa có giao dịch
    if (totalTransactions == 0) {
      return '🌸 Hãy thêm giao dịch đầu tiên để mình có thể tư vấn cho bạn nhé!';
    }

    if (savingRate < 0) {
      return '💡 Lời khuyên: Hãy bắt đầu bằng cách ghi chép lại tất cả chi tiêu. '
          'Cắt giảm 20% chi tiêu không cần thiết sẽ giúp bạn cân bằng tài chính!';
    } else if (savingRate < 10) {
      return '💡 Lời khuyên: Áp dụng quy tắc 50/30/20: 50% nhu cầu, 30% mong muốn, 20% tiết kiệm. '
          'Cố gắng tiết kiệm ${Helpers.formatMoney(monthlySaving * 0.2)} mỗi tháng!';
    } else if (savingRate < 20) {
      return '💡 Lời khuyên: Tuyệt vời! Mỗi tháng bạn tiết kiệm ${Helpers.formatMoney(monthlySaving)}. '
          'Hãy đầu tư số tiền này vào quỹ ETF hoặc gửi tiết kiệm để sinh lời!';
    } else {
      return '💡 Lời khuyên: Bạn là chuyên gia quản lý tài chính! 🎉 '
          'Hãy chia sẻ bí quyết với bạn bè và tiếp tục duy trì thói quen tốt này!';
    }
  }

  // Lấy gợi ý ngắn gọn cho card AI
  static String getQuickSuggestion(Map<String, dynamic> analysis) {
    double savingRate = analysis['savingRate'];
    double monthlySaving = analysis['monthlySaving'];
    String topCategory = analysis['topCategory'];
    double totalTransactions = analysis['totalTransactions'];

    if (totalTransactions == 0) {
      return '✨ Hãy thêm giao dịch đầu tiên để AI có thể phân tích!';
    }

    if (savingRate < 0) {
      return '⚠️ Bạn đang chi nhiều hơn thu ${Helpers.formatMoney(-monthlySaving)}. '
          'Hãy xem lại khoản chi cho "$topCategory"!';
    } else if (savingRate < 10) {
      return '📊 Tỷ lệ tiết kiệm ${savingRate.toStringAsFixed(1)}%. '
          'Hãy tiết kiệm thêm ${Helpers.formatMoney(monthlySaving * 0.2)} mỗi tháng!';
    } else if (savingRate < 20) {
      return '🎯 Tốt! Bạn đã tiết kiệm ${savingRate.toStringAsFixed(1)}% thu nhập. '
          'Duy trì nhé!';
    } else {
      return '🌟 Xuất sắc! Bạn đã tiết kiệm ${savingRate.toStringAsFixed(1)}% thu nhập. '
          'Hãy đầu tư để sinh lời!';
    }
  }

  // Đánh giá mức độ chi tiêu
  static String getSpendingStatus(double totalIncome, double totalExpense) {
    if (totalIncome == 0) return 'Chưa có dữ liệu';

    double ratio = totalExpense / totalIncome;

    if (ratio > 1) {
      return '⚠️ Chi tiêu vượt quá thu nhập';
    } else if (ratio > 0.8) {
      return '⚠️ Chi tiêu khá cao, hãy tiết kiệm hơn';
    } else if (ratio > 0.6) {
      return '✅ Chi tiêu hợp lý';
    } else if (ratio > 0.4) {
      return '🌟 Chi tiêu tốt, hãy duy trì';
    } else {
      return '🎉 Chi tiêu rất tiết kiệm!';
    }
  }

  // Lấy biểu tượng cảm xúc dựa trên tình hình tài chính
  static String getEmotion(double totalIncome, double totalExpense) {
    if (totalIncome == 0) return '😊';

    double ratio = totalExpense / totalIncome;

    if (ratio > 1) return '😰';
    if (ratio > 0.8) return '😅';
    if (ratio > 0.6) return '🙂';
    if (ratio > 0.4) return '😊';
    return '🎉';
  }
}
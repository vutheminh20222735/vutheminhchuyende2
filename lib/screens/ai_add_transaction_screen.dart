import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AIAddTransactionScreen extends StatefulWidget {
  final int? walletId;
  final VoidCallback onSave;

  const AIAddTransactionScreen({
    super.key,
    this.walletId,
    required this.onSave,
  });

  @override
  State<AIAddTransactionScreen> createState() => _AIAddTransactionScreenState();
}

class _AIAddTransactionScreenState extends State<AIAddTransactionScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _voiceInputController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _type = 'expense';
  String _category = 'Ăn uống';
  DateTime _selectedDate = DateTime.now();
  bool _isAILoading = false;
  String _aiSuggestion = '';

  final List<String> _quickSuggestions = [
    'Mua cơm trưa 50k',
    'Đổ xăng 200k',
    'Mua sắm siêu thị 300k',
    'Lương tháng 15tr',
    'Ăn tối nhà hàng 500k',
    'Tiền điện 150k',
  ];

  Future<void> _processWithAI() async {
    if (_voiceInputController.text.isEmpty) return;

    setState(() {
      _isAILoading = true;
      _aiSuggestion = 'Đang phân tích...';
    });

    await Future.delayed(const Duration(seconds: 1));

    final input = _voiceInputController.text.toLowerCase();
    String extractedTitle = '';
    double extractedAmount = 0;
    String extractedType = 'expense';
    String extractedCategory = 'Khác';

    // AI phân tích
    if (input.contains('lương') || input.contains('lĩnh') || input.contains('thưởng')) {
      extractedType = 'income';
      extractedCategory = 'Lương';
      extractedTitle = 'Lương';
    } else if (input.contains('mua sắm') || input.contains('shopping')) {
      extractedType = 'expense';
      extractedCategory = 'Mua sắm';
      extractedTitle = input.replaceAll(RegExp(r'\d+(?:\.\d+)?'), '').trim();
    } else if (input.contains('ăn') || input.contains('cơm') || input.contains('nhà hàng')) {
      extractedType = 'expense';
      extractedCategory = 'Ăn uống';
      extractedTitle = input.replaceAll(RegExp(r'\d+(?:\.\d+)?'), '').trim();
    } else if (input.contains('xăng') || input.contains('di chuyển')) {
      extractedType = 'expense';
      extractedCategory = 'Di chuyển';
      extractedTitle = 'Đổ xăng';
    } else if (input.contains('điện') || input.contains('nước') || input.contains('hóa đơn')) {
      extractedType = 'expense';
      extractedCategory = 'Hóa đơn';
      extractedTitle = input.replaceAll(RegExp(r'\d+(?:\.\d+)?'), '').trim();
    } else {
      extractedTitle = _voiceInputController.text;
    }

    // Trích xuất
    final amountMatches = RegExp(r'\d+(?:\.\d+)?').allMatches(input);
    if (amountMatches.isNotEmpty) {
      double total = 0;
      for (var match in amountMatches) {
        total += double.parse(match.group(0)!);
      }
      extractedAmount = total;
    }

    setState(() {
      _titleController.text = extractedTitle.isNotEmpty ? extractedTitle : _voiceInputController.text;
      if (extractedAmount > 0) {
        _amountController.text = extractedAmount.toString();
      }
      _type = extractedType;
      _category = extractedCategory;
      _aiSuggestion = '✅ AI đã phân tích: ${extractedType == 'income' ? 'Thu nhập' : 'Chi tiêu'} - $extractedCategory\n💰 Số tiền: ${extractedAmount > 0 ? Helpers.formatMoney(extractedAmount) : 'Chưa xác định'}';
      _isAILoading = false;
    });
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền')),
      );
      return;
    }

    final transaction = Transaction(
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _type,
      category: _category,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      walletId: widget.walletId,
    );

    await _db.insertTransaction(transaction);
    widget.onSave();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm giao dịch!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm giao dịch bằng AI'),
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card AI
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
                      Expanded(
                        child: Text(
                          'Nhập bằng giọng nói hoặc văn bản',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _voiceInputController,
                    decoration: InputDecoration(
                      hintText: 'VD: "Mua cơm trưa 50k" hoặc "Lương tháng 15 triệu"',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: _isAILoading ? null : _processWithAI,
                        icon: _isAILoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.auto_awesome, color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (_aiSuggestion.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _aiSuggestion,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Gợi ý nhanh
            const Text(
              'Gợi ý nhanh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _voiceInputController.text = _quickSuggestions[index];
                      _processWithAI();
                    },
                    child: Chip(
                      label: Text(_quickSuggestions[index]),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Form thông tin
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // Loại giao dịch
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Chi tiêu'),
                            selected: _type == 'expense',
                            onSelected: (selected) {
                              if (selected) setState(() => _type = 'expense');
                            },
                            selectedColor: Colors.red.shade100,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Thu nhập'),
                            selected: _type == 'income',
                            onSelected: (selected) {
                              if (selected) setState(() => _type = 'income');
                            },
                            selectedColor: Colors.green.shade100,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // Tiêu đề
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Số tiền
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền',
                        border: OutlineInputBorder(),
                        prefixText: '₫ ',
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Danh mục
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                      ),
                      items: (_type == 'expense'
                          ? Categories.expenseCategories
                          : Categories.incomeCategories
                      ).map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                    ),

                    const SizedBox(height: 15),

                    // Ngày
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Ngày'),
                      subtitle: Text(Helpers.formatDate(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    // Ghi chú
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Nút lưu
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.purple,
              ),
              child: const Text('Thêm giao dịch'),
            ),
          ],
        ),
      ),
    );
  }
}
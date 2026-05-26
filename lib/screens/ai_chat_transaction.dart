import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AIChatTransaction extends StatefulWidget {
  final int? walletId;
  final int? userId;
  final VoidCallback onSave;

  const AIChatTransaction({
    super.key,
    this.walletId,
    this.userId,
    required this.onSave,
  });

  @override
  State<AIChatTransaction> createState() => _AIChatTransactionState();
}

class _AIChatTransactionState extends State<AIChatTransaction> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isAITyping = false;
  bool _waitingForMore = false;

  String get _chatHistoryKey => 'chat_history_user_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_chatHistoryKey);

    if (historyJson != null && historyJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = List<dynamic>.from(jsonDecode(historyJson));
        _messages = decoded.map((item) {
          return ChatMessage(
            text: item['text'],
            isUser: item['isUser'],
            timestamp: DateTime.parse(item['timestamp']),
          );
        }).toList();
        print('✅ Đã load ${_messages.length} tin nhắn lịch sử');
        _scrollToBottom();
        setState(() {});
      } catch (e) {
        print('❌ Lỗi load lịch sử: $e');
        _addWelcomeMessage();
      }
    } else {
      _addWelcomeMessage();
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> history = _messages.map((msg) {
      return {
        'text': msg.text,
        'isUser': msg.isUser,
        'timestamp': msg.timestamp.toIso8601String(),
      };
    }).toList();

    await prefs.setString(_chatHistoryKey, jsonEncode(history));
  }

  Future<void> _clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatHistoryKey);
  }

  Map<String, dynamic> _getCategory(String text) {
    final input = text.toLowerCase();

    if (input.contains('lương') || input.contains('luong') ||
        input.contains('lĩnh') || input.contains('linh') ||
        input.contains('thu nhập') || input.contains('thu nhap')) {
      return {'name': 'Lương', 'icon': '💰', 'display': 'Lương', 'type': 'income'};
    }

    if (input.contains('thưởng') || input.contains('thuong') ||
        input.contains('bonus')) {
      return {'name': 'Thưởng', 'icon': '🎁', 'display': 'Thưởng', 'type': 'income'};
    }

    if (input.contains('xăng') || input.contains('xang') ||
        input.contains('đổ xăng') || input.contains('do xang') ||
        input.contains('taxi') || input.contains('grab') ||
        input.contains('xe') || input.contains('di chuyển') || input.contains('di chuyen')) {
      return {'name': 'Di chuyển', 'icon': '🚗', 'display': 'Di chuyển', 'type': 'expense'};
    }

    if (input.contains('mua') || input.contains('sắm') || input.contains('sam') ||
        input.contains('quần áo') || input.contains('quan ao') ||
        input.contains('giày') || input.contains('giay') ||
        input.contains('shopping')) {
      return {'name': 'Mua sắm', 'icon': '🛍️', 'display': 'Mua sắm', 'type': 'expense'};
    }

    if (input.contains('ăn') || input.contains('an') ||
        input.contains('cơm') || input.contains('com') ||
        input.contains('phở') || input.contains('pho') ||
        input.contains('bún') || input.contains('bun') ||
        input.contains('nhà hàng') || input.contains('nha hang')) {
      return {'name': 'Ăn uống', 'icon': '🍜', 'display': 'Đi ăn', 'type': 'expense'};
    }

    if (input.contains('điện') || input.contains('dien') ||
        input.contains('nước') || input.contains('nuoc') ||
        input.contains('internet') || input.contains('wifi')) {
      return {'name': 'Hóa đơn', 'icon': '📄', 'display': 'Hóa đơn', 'type': 'expense'};
    }

    if (input.contains('phim') || input.contains('game') ||
        input.contains('xem') || input.contains('giải trí')) {
      return {'name': 'Giải trí', 'icon': '🎬', 'display': 'Giải trí', 'type': 'expense'};
    }

    if (input.contains('khám') || input.contains('kham') ||
        input.contains('thuốc') || input.contains('thuoc')) {
      return {'name': 'Sức khỏe', 'icon': '💪', 'display': 'Sức khỏe', 'type': 'expense'};
    }

    return {'name': 'Khác', 'icon': '📌', 'display': 'Chi tiêu', 'type': 'expense'};
  }

  final List<String> _greetings = [
    "Chào bạn! Hôm nay thế nào? 😊",
    "Hey! Có gì muốn nhờ mình không? ✨",
    "Chào cậu! Mình sẵn sàng giúp cậu nè 💕",
  ];

  final List<String> _encouragements = [
    "💪 Cố lên bạn nhé! Mỗi ngày tiết kiệm một chút, tương lai sẽ rạng rỡ!",
    "🌟 Bạn làm tốt lắm! Hãy tiếp tục duy trì thói quen này nhé!",
    "🎯 Tuyệt vời! Quản lý chi tiêu tốt là bước đầu để thành công!",
    "💖 Mình tin bạn sẽ làm được! Hãy luôn vững bước nhé!",
  ];

  void _addWelcomeMessage() {
    final welcomeMessage = _greetings[_greetings.length - 1] +
        "\n\nMình giúp bạn ghi lại thu chi nè!\n"
            "Chỉ cần nói với mình:\n"
            "💰 'Lương 15tr' - Thu nhập\n"
            "🍜 'Ăn cơm 50k' - Chi tiêu\n"
            "🚗 'Đổ xăng 200k' - Di chuyển\n"
            "🛍️ 'Mua quần áo 500k' - Mua sắm";

    _messages.add(ChatMessage(
      text: welcomeMessage,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _saveChatHistory();
    setState(() {});
  }

  void _addMessage(String text, bool isUser) {
    _messages.add(ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));
    _saveChatHistory();
    _scrollToBottom();
    setState(() {});
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processUserMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addMessage(message, true);
    _messageController.clear();

    setState(() => _isAITyping = true);
    await Future.delayed(const Duration(milliseconds: 500));

    final response = await _aiProcessMessage(message);

    setState(() => _isAITyping = false);
    _addMessage(response, false);
  }

  Future<String> _aiProcessMessage(String message) async {
    final input = message.toLowerCase();

    if (_waitingForMore) {
      _waitingForMore = false;

      if (input.contains('không') || input.contains('thôi') ||
          input.contains('đủ') || input.contains('hết') ||
          input.contains('ko')) {
        final encouragement = _encouragements[_messages.length % _encouragements.length];
        return "Cảm ơn bạn! 🌸\n\n$encouragement\n\nHẹn gặp lại! 💕";
      }
      return await _processTransaction(message);
    }

    if (input.contains('chào') || input.contains('hi') || input.contains('hello')) {
      return _getRandomGreeting();
    }

    if (input.contains('cảm ơn') || input.contains('cam on')) {
      return "Không có gì! Rất vui được giúp bạn! 💕";
    }

    return await _processTransaction(message);
  }
  // Thêm method static để xóa lịch sử chat
  static Future<void> clearChatHistory(int? userId) async {
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final chatKey = 'chat_history_user_$userId';
    await prefs.remove(chatKey);
    print('🗑️ Đã xóa lịch sử chat của user $userId');
  }
  Future<String> _processTransaction(String message) async {
    final input = message.toLowerCase();
    final category = _getCategory(input);
    double? amount = _extractAmount(message);

    if (amount == null) {
      return "Mình chưa thấy số tiền, bạn nói lại với số tiền nhé! 💰\n"
          "Ví dụ: 'Ăn cơm 50k' hoặc 'Lương 15tr'";
    }

    String type = category['type'];
    String typeIcon = type == 'income' ? '💰' : '💸';
    String typeText = type == 'income' ? 'Thu nhập' : 'Chi tiêu';
    String title = category['display'];
    String categoryName = category['name'];
    String icon = category['icon'];

    final transaction = Transaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: type,
      category: categoryName,
      note: null,
      walletId: widget.walletId,
      userId: widget.userId,
    );

    // Lưu vào database
    await _db.insertTransaction(transaction);
    print('✅ Đã lưu giao dịch: $title - ${Helpers.formatMoney(amount)}');
    
    widget.onSave();
    print('✅ Đã gọi onSave để refresh trang chủ');

    _waitingForMore = true;

    return "$typeIcon **$typeText:** $icon $title - ${Helpers.formatMoney(amount)}\n\n"
        "✅ Đã lưu!\n\n"
        "Bạn muốn thêm gì nữa không? 😊";
  }

  String _getRandomGreeting() {
    final greetings = [
      "Chào bạn! Có gì mình giúp được không? 😊",
      "Hey! Lại gặp nhau rồi! ✨",
      "Chào cậu! Hôm nay thế nào? 💕",
    ];
    return greetings[_messages.length % greetings.length];
  }

  double? _extractAmount(String text) {
    final amountPattern = RegExp(r'(\d+(?:\.\d+)?)\s*(k|K|ngan|ngàn|tr|triệu)?', caseSensitive: false);
    final matches = amountPattern.allMatches(text);

    if (matches.isNotEmpty) {
      double total = 0;
      for (var match in matches) {
        double value = double.parse(match.group(1)!);
        String? unit = match.group(2)?.toLowerCase();

        if (unit == 'k' || unit == 'ngan' || unit == 'ngàn') {
          value *= 1000;
        } else if (unit == 'tr' || unit == 'triệu') {
          value *= 1000000;
        }

        total += value;
      }
      return total;
    }
    return null;
  }

  @override
  void dispose() {
    _saveChatHistory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar hình ảnh
            ClipOval(
              child: Container(
                width: 40,
                height: 40,
                color: Colors.transparent,  // Nền trong suốt
                child: Image.asset(
                  'assets/images/mina.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mina',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Trợ lý AI',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveChatHistory();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa lịch sử'),
                  content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _clearChatHistory();
                        setState(() {
                          _messages.clear();
                          _waitingForMore = false;
                          _addWelcomeMessage();
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa lịch sử trò chuyện')),
                        );
                      },
                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                itemCount: _messages.length + (_isAITyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isAITyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Nhắn với Mina...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: (text) => _processUserMessage(text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _processUserMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF9C27B0) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey.shade500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
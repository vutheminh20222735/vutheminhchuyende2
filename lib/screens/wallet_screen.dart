import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/wallet.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final DatabaseService _db = DatabaseService();
  List<Wallet> _wallets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _isLoading = true);
    _wallets = await _db.getWallets();
    setState(() => _isLoading = false);
  }

  Future<void> _addWallet() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ví mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên ví', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _db.insertWallet(Wallet(name: controller.text));
                await _loadWallets();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm ví ${controller.text}')));
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _setDefaultWallet(Wallet wallet) async {
    for (var w in _wallets) {
      if (w.isDefault) await _db.updateWallet(w.copyWith(isDefault: false));
    }
    await _db.updateWallet(wallet.copyWith(isDefault: true));
    await _loadWallets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${wallet.name} đã được đặt làm ví mặc định')));
    }
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    if (wallet.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa ví mặc định')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ví'),
        content: Text('Bạn có chắc muốn xóa ví "${wallet.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await _db.deleteWallet(wallet.id!);
              await _loadWallets();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa ví ${wallet.name}')));
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
      appBar: AppBar(title: const Text('Quản lý ví')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _wallets.length,
        itemBuilder: (context, index) {
          final wallet = _wallets[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: wallet.isDefault ? Colors.blue : Colors.grey.shade300,
                child: Icon(Icons.account_balance_wallet, color: wallet.isDefault ? Colors.white : Colors.grey),
              ),
              title: Text(wallet.name, style: TextStyle(fontWeight: wallet.isDefault ? FontWeight.bold : null)),
              subtitle: wallet.isDefault ? const Text('Ví mặc định') : null,
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  if (!wallet.isDefault)
                    PopupMenuItem(child: const Text('Đặt làm mặc định'), onTap: () => _setDefaultWallet(wallet)),
                  PopupMenuItem(child: const Text('Xóa', style: TextStyle(color: Colors.red)), onTap: () => _deleteWallet(wallet)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addWallet, backgroundColor: Colors.blue, child: const Icon(Icons.add)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Chưa có ví nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Nhấn nút + để thêm ví mới', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
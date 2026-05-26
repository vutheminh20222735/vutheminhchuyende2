import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/user.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'expense_tracker.db');

    print('📁 Database path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        print('✅ Database đã mở thành công');
        final result = await db.rawQuery("SELECT COUNT(*) as count FROM users");
        print('📊 Số lượng users trong DB: ${result.first['count']}');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔄 Tạo database mới (lần đầu tiên chạy app)');

    // 1. Tạo bảng users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    print('✅ Đã tạo bảng users');

    // 2. Tạo bảng wallets
    await db.execute('''
      CREATE TABLE wallets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        isDefault INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng wallets');

    // 3. Tạo bảng transactions
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        walletId INTEGER,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng transactions');

    // 4. Tạo bảng budgets - ĐÃ SỬA: limit -> budget_limit
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        budget_limit REAL NOT NULL,
        spent REAL NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng budgets');

    // 5. Tạo bảng saving_goals
    await db.execute('''
      CREATE TABLE saving_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        targetDate TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng saving_goals');

    // 6. Tạo bảng debts
    await db.execute('''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        note TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng debts');

    // 7. Tạo bảng challenges
    await db.execute('''
      CREATE TABLE challenges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    print('✅ Đã tạo bảng challenges');

    print('✅ Đã tạo database thành công!');
  }

  // ==================== USER METHODS ====================
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByPhone(String phone) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List<User>.from(maps.map((map) => User.fromMap(map)));
  }

  // ==================== WALLET METHODS ====================
  Future<List<Wallet>> getWallets({int? userId}) async {
    final db = await database;

    if (userId != null) {
      final List<Map<String, dynamic>> maps = await db.query(
        'wallets',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      return List<Wallet>.from(maps.map((map) => Wallet.fromMap(map)));
    }

    final List<Map<String, dynamic>> maps = await db.query('wallets');
    return List<Wallet>.from(maps.map((map) => Wallet.fromMap(map)));
  }

  Future<Wallet?> getDefaultWallet({int? userId}) async {
    final db = await database;

    if (userId != null) {
      final List<Map<String, dynamic>> maps = await db.query(
        'wallets',
        where: 'isDefault = 1 AND userId = ?',
        whereArgs: [userId],
      );
      if (maps.isNotEmpty) {
        return Wallet.fromMap(maps.first);
      }
    } else {
      final List<Map<String, dynamic>> maps = await db.query(
        'wallets',
        where: 'isDefault = 1',
      );
      if (maps.isNotEmpty) {
        return Wallet.fromMap(maps.first);
      }
    }
    return null;
  }

  Future<int> insertWallet(Wallet wallet) async {
    final db = await database;
    return await db.insert('wallets', wallet.toMap());
  }

  Future<int> updateWallet(Wallet wallet) async {
    final db = await database;
    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(int id) async {
    final db = await database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSACTION METHODS ====================
  Future<List<Transaction>> getTransactions({int? walletId, int? userId}) async {
    final db = await database;
    List<String> conditions = [];
    List<Object?> whereArgs = [];

    if (walletId != null) {
      conditions.add('walletId = ?');
      whereArgs.add(walletId);
    }

    if (userId != null) {
      conditions.add('userId = ?');
      whereArgs.add(userId);
    }

    String where = conditions.isNotEmpty ? conditions.join(' AND ') : '';

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return List<Transaction>.from(maps.map((map) => Transaction.fromMap(map)));
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== STATISTICS METHODS ====================
  Future<double> getTotalIncome({int? walletId, int? userId}) async {
    final db = await database;
    List<String> conditions = ["type = 'income'"];
    List<Object?> whereArgs = [];

    if (walletId != null) {
      conditions.add('walletId = ?');
      whereArgs.add(walletId);
    }

    if (userId != null) {
      conditions.add('userId = ?');
      whereArgs.add(userId);
    }

    final String where = conditions.join(' AND ');
    print('📊 SQL getTotalIncome: $where, args: $whereArgs');

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $where',
      whereArgs,
    );
    final total = result.first['total'] as double? ?? 0.0;
    print('📊 Total Income: $total');
    return total;
  }

  Future<double> getTotalExpense({int? walletId, int? userId}) async {
    final db = await database;
    List<String> conditions = ["type = 'expense'"];
    List<Object?> whereArgs = [];

    if (walletId != null) {
      conditions.add('walletId = ?');
      whereArgs.add(walletId);
    }

    if (userId != null) {
      conditions.add('userId = ?');
      whereArgs.add(userId);
    }

    final String where = conditions.join(' AND ');
    print('📊 SQL getTotalExpense: $where, args: $whereArgs');

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $where',
      whereArgs,
    );
    final total = result.first['total'] as double? ?? 0.0;
    print('📊 Total Expense: $total');
    return total;
  }

  Future<Map<String, double>> getCategorySpending({int? walletId, int? userId}) async {
    final db = await database;
    List<String> conditions = ["type = 'expense'"];
    List<Object?> whereArgs = [];

    if (walletId != null) {
      conditions.add('walletId = ?');
      whereArgs.add(walletId);
    }

    if (userId != null) {
      conditions.add('userId = ?');
      whereArgs.add(userId);
    }

    final String where = conditions.join(' AND ');

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE $where GROUP BY category',
      whereArgs,
    );

    Map<String, double> categorySpending = {};
    for (var row in result) {
      categorySpending[row['category'] as String] = row['total'] as double;
    }
    return categorySpending;
  }

  // ==================== DATA MANAGEMENT ====================
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('wallets');
    await db.delete('users');
    print('✅ Đã reset toàn bộ database');
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
    print('✅ Đã xóa tất cả giao dịch');
  }

  Future<void> deleteTransactionsByUser(int userId) async {
    final db = await database;
    await db.delete('transactions', where: 'userId = ?', whereArgs: [userId]);
    print('✅ Đã xóa giao dịch của user $userId');
  }
}
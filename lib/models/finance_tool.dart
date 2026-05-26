class SavingGoal {
  final int? id;
  final String name;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;  // Ngày mục tiêu (có thể bỏ nếu không dùng)
  final DateTime createdAt;   // THÊM: Ngày tạo mục tiêu
  final int? userId;

  SavingGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.targetDate,
    required this.createdAt,   // THÊM
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),  // THÊM
      'userId': userId,
    };
  }

  factory SavingGoal.fromMap(Map<String, dynamic> map) {
    return SavingGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      targetDate: DateTime.parse(map['targetDate']),
      createdAt: DateTime.parse(map['createdAt']),  // THÊM
      userId: map['userId'],
    );
  }

  double get remaining => targetAmount - currentAmount;
  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
}

class Debt {
  final int? id;
  final String name;
  final double totalAmount;
  double paidAmount;
  final DateTime dueDate;
  final DateTime createdAt;   // THÊM: Ngày tạo món nợ
  final String? note;
  final int? userId;

  Debt({
    this.id,
    required this.name,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.dueDate,
    required this.createdAt,   // THÊM
    this.note,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),  // THÊM
      'note': note,
      'userId': userId,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      totalAmount: map['totalAmount'],
      paidAmount: map['paidAmount'],
      dueDate: DateTime.parse(map['dueDate']),
      createdAt: DateTime.parse(map['createdAt']),  // THÊM
      note: map['note'],
      userId: map['userId'],
    );
  }

  double get remaining => totalAmount - paidAmount;
  double get percentage => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
}
class Budget {
  final int? id;
  final String category;
  double budgetLimit;
  double spent;
  final DateTime createdAt;
  final int? userId;

  Budget({
    this.id,
    required this.category,
    required this.budgetLimit,
    this.spent = 0,
    required this.createdAt,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'budget_limit': budgetLimit,
      'spent': spent,
      'created_at': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      budgetLimit: map['budget_limit'],
      spent: map['spent'],
      createdAt: DateTime.parse(map['created_at']),
      userId: map['userId'],
    );
  }

  double get remaining => budgetLimit - spent;
  double get percentage => budgetLimit > 0 ? (spent / budgetLimit) * 100 : 0;
}

// ... các class SavingGoal, Debt, Challenge tương tự

class Challenge {
  final int? id;
  final String name;
  final String description;
  final double targetAmount;
  double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;   // THÊM: Ngày tạo thử thách
  bool isCompleted;
  final int? userId;

  Challenge({
    this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.startDate,
    required this.endDate,
    required this.createdAt,   // THÊM
    this.isCompleted = false,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),  // THÊM
      'isCompleted': isCompleted ? 1 : 0,
      'userId': userId,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      createdAt: DateTime.parse(map['createdAt']),  // THÊM
      isCompleted: map['isCompleted'] == 1,
      userId: map['userId'],
    );
  }

  double get remaining => targetAmount - currentAmount;
  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  int get daysLeft => endDate.difference(DateTime.now()).inDays;
}